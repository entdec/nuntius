# frozen_string_literal: true

require 'pp'

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class TransportDeliveryJob < ApplicationJob
    # TODO: add this as configuration
    # queue_as :message

    def perform(provider_name, message)
      return if message.delivered?
      return if message.parent_message&.delivered?

      provider = BaseProvider.class_from_name(provider_name, message.transport).new

      unless message.draft?
        message = message.dup
        message.state = 'draft'
      end
      message.provider = provider_name
      message = provider.deliver(message)
      message.save! unless message.draft?

      # First refresh check is after 5 seconds
      if message.delivered?
        message.cleanup!
      else
        TransportRefreshJob.set(wait: 5).perform_later(provider_name, message)
      end
    end
  end
end
