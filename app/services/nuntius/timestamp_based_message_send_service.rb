# frozen_string_literal: true

require 'query_constructor'

module Nuntius
  class TimestampBasedMessageSendService < ApplicationService
    def initialize(message)
      @message = message
    end

    def perform
      return unless @message.interval.present?
      return unless @message.timestamp.present?

      base_scope = Kernel.const_get(@message.klass).where(channel: @message.channel)
      base_scope = base_scope.timestamp_based_messages_scope if Kernel.const_get(@message.klass).respond_to?(:timestamp_based_messages_scope)
      base_scope = QueryConstructor.new(@message, base_scope, @message.query, {}).construct if @message.query.present?

      # We want to be able to send messages x minutes after a timestamp or x minutes before
      base_scope = base_scope.where("(#{@message.timestamp} + '1m'::INTERVAL * :interval) <= :now::TIMESTAMP", now: Time.current, interval: @message.interval)

      # We make a window of an hour, we'll retry selecting this record for an hour before giving up.
      base_scope = base_scope.where("(#{@message.timestamp} + '1m'::INTERVAL * :interval) >= :now::TIMESTAMP", now: Time.current, interval: @message.interval + 60)

      # Don't look at items before message creation time and items older than 6 months ago
      base_scope = base_scope.where("#{@message.timestamp} > ? AND #{@message.timestamp} > ?", @message.updated_at, 6.months.ago)

      # Don't look at items for which we've already sent a message
      base_scope = base_scope.where("\"#{@message.klass.tableize}\".\"id\" NOT IN (SELECT messagable_id FROM message_instances WHERE messagable_type = ? AND message_id = ?)", @message.klass, @message.id)

      Rails.logger.debug "TimestampBasedMessageSendService - SQL query: #{base_scope.to_sql}"

      base_scope.each do |item|
        Message.transaction do
          begin
            @message.process_with_object(item, {})
          rescue StandardError => e
            Rails.logger.error "Exception during processing for #{item}: #{e}"
          end
        end
      end
    end
  end
end
