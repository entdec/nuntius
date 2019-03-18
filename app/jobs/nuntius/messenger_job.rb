# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class MessengerJob < ApplicationJob
    queue_as Nuntius.config.jobs_queue_name

    def perform(obj, event, params = {})
      return unless obj

      messenger = Nuntius::BaseMessenger.messenger_for_obj(obj).new(obj, event, params)
      templates = messenger.call
      messenger.dispatch(templates) if templates
    end
  end
end
