# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class MessengerJob < ApplicationJob
    def perform(obj, event, params = {})
      return unless obj

      messenger = Nuntius::BaseMessenger.messenger_for_obj(obj).new(obj, event, params)
      return unless messenger.is_a?(Nuntius::CustomMessenger) || messenger.respond_to?(event.to_sym)

      result = messenger.call
      return if result == false

      templates = messenger.templates
      messenger.dispatch(templates) if templates.present?
    end
  end
end
