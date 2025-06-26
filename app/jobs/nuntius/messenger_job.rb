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

        result = messenger.call
        return if result == false

        templates = messenger.templates
        messenger.dispatch(templates) if templates.exists?
      end
    end

    def cleanup_nuntius_events
      Nuntius::Event.where(
        transitionable: arguments.first,
        transition_event: arguments.second.to_s
      ).delete_all
    end
  end
end
