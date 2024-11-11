# frozen_string_literal: true

module Nuntius
  class TimebasedEventsJob < ApplicationJob
    def perform
      Nuntius::Template.where.not(interval: nil).each do |template|
        messenger_class = Nuntius::BaseMessenger.messenger_for_class(template.klass)

        messenger_class.timebased_scope_for(template).each do |object|
          messenger = messenger_class.new(object, template.event)
          next unless messenger.is_a?(Nuntius::CustomMessenger) || messenger.respond_to?(template.event.to_sym)

          messenger.dispatch([template])
        end
      end
    end
  end
end
