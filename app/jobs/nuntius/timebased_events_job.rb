# frozen_string_literal: true

module Nuntius
  class TimebasedEventsJob < ApplicationJob
    # A template held for sending more than its limit (see hold)
    class LimitExceeded < StandardError; end

    # A Postgres advisory lock's key, for one run at a time
    LOCK = Zlib.crc32("Nuntius::TimebasedEventsJob")

    # One run at a time: a run alongside another one (a slow run, with cron
    # starting the next) would find the same objects not sent yet, and send
    # them again. It leaves them to the run that's going.
    def perform
      return unless lock("pg_try_advisory_lock")

      begin
        send_due
      ensure
        lock("pg_advisory_unlock")
      end
    end

    private

    # Past the query cache, which jobs run with: a cached unlock wouldn't
    # unlock, and no run would get the lock again
    def lock(function)
      Nuntius::ApplicationRecord.uncached do
        Nuntius::ApplicationRecord.connection.select_value("SELECT #{function}(#{LOCK})")
      end
    end

    def send_due
      Nuntius::Template.where(enabled: true).where.not(interval: nil).each do |template|
        messenger_class = Nuntius::BaseMessenger.messenger_for_class(template.klass)
        unless messenger_class&.timestamp_for(template.event, template.klass)
          Nuntius.config.logger.warn("Nuntius: template #{template.id} (#{template.klass} #{template.event}) has an interval, but #{template.event} isn't around a timestamp: not sent")
          next
        end

        limit = template.send_limit
        recipients = messenger_class.timebased_recipients(template, max: limit + 1)
        next hold(template, limit) if recipients.size > limit

        recipients.each { |object| messenger_class.new(object, template.event).dispatch([template]) }
      end
    end

    # A template that would send more than its limit sends nothing, and is
    # disabled until someone checks it: a mistake shouldn't mail everyone
    def hold(template, limit)
      template.update_columns(enabled: false, updated_at: Time.current)
      message = "Nuntius: template #{template.id} (#{template.description}) would send more than #{limit} messages, so it's disabled and sent nothing. " \
        "Check its event and conditions, or raise its limit, and enable it again."
      Nuntius.config.logger.error(message)
      Rails.error.report(LimitExceeded.new(message), handled: true, context: {template_id: template.id})
    end
  end
end
