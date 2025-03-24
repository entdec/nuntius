# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class MessengerJob < ApplicationJob
    after_perform :cleanup_nuntius_events
    def perform(obj, event, params = {})
      return unless obj
      ActiveRecord::Base.transaction do
        messenger = Nuntius::BaseMessenger.messenger_for_obj(obj).new(obj, event, params)
        return unless messenger.is_a?(Nuntius::CustomMessenger) || messenger.respond_to?(event.to_sym)

        messenger.call
        templates = messenger.templates
        messenger.dispatch(templates) if templates.present?
      end
      cleanup_nuntius_events(obj, event)
    end

    def cleanup_nuntius_events(obj, event)

      nuntius_events = Nuntius::Event.where(
        transitionable_id: obj["id"],
        transitionable_type: obj["type"],
        transition_event: event.to_s
      )
      nuntius_events.destroy_all
    end
  end
end
