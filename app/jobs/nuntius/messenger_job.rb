# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class MessengerJob < ApplicationJob
    queue_as Nuntius.config.jobs_queue_name

    def perform(obj, event, params = {})
      return unless obj

      messenger = Nuntius::BaseMessenger.messenger_for_obj(obj).new(obj, event, params)
      messenger.call
      templates = messenger.templates
      messenger.dispatch(templates) if templates.present?
    end
  end
end
