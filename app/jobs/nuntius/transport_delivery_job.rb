# frozen_string_literal: true

require 'pp'

# This job will be called only once for each provider sent out to deliver the job
module Nuntius
  class TransportDeliveryJob < ApplicationJob
    # TODO: add this as configuration
    # queue_as :message

    def perform(provider_name, message)
      return if message.delivered?
      return if message.parent_message&.delivered?

      provider = BaseProvider.class_from_name(provider_name, message.transport).new

      if message.provider != provider_name
        original_message = message
        message = message.dup
        message.parent_message = original_message
        message.status = 'draft'
        message.provider_id = ''
      end
      message.provider = provider_name
      message.save!

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
