# frozen_string_literal: true

# This job will be called only once for each provider sent out to deliver the job
module Nuntius
  class TransportDeliveryJob < ApplicationJob
    def perform(provider_name, message)
      return if message.delivered_or_blocked?
      return if message.parent_message&.delivered_or_blocked?

      if message.provider != provider_name
        original_message = message
        message = message.dup
        message.parent_message = original_message
        message.status = "pending"
        message.provider_id = ""
      end
      message.provider = provider_name
      message.save!

      provider = Nuntius::BaseProvider.class_from_name(provider_name, message.transport).new(message)
      message = provider.deliver
      message.save! unless message.pending?

      # First refresh check is after 5 seconds
      if message.delivered_or_blocked?
        message.cleanup!
      else
        Nuntius::TransportRefreshJob.set(wait: 5).perform_later(provider_name, message) unless Rails.env.development?
      end
    end
  end
end
