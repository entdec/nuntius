# frozen_string_literal: true

module Nuntius
  class TimebasedEventsRunner < ApplicationRunner
    def perform
      Nuntius::Template.where.not(interval: nil).each do |template|
        messenger = Nuntius::BaseMessenger.messenger_for_class(template.klass)
        event_name = event.to_s
        next unless messenger.timebased_scopes.include?(template.event)
        next unless %w[before after].detect { |s| event_name.start_with?(s) }

        if event_name.start_with?('before')
          operator  = '<='
          timestamp = Time.parse("-#{interval}")
        elsif event_name.start_with?('after')
          operator  = '>='
          timestamp = Time.parse("+#{interval}")
        end

        messenger.public_send(template.event, timestamp).each do |object|
          Nuntius.with(object).event(template.event)
        end
      end
    end
  end
end
