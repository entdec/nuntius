# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class TransportRefreshJob < ApplicationJob
    def perform(provider_name, message)
      return if message.delivered_or_blocked? || message.refreshes >= 3

      provider = Nuntius::BaseProvider.class_from_name(provider_name, message.transport).new(message)
      message = provider.refresh
      # FIXME: This may need to be more atomic
      message.refreshes += 1
      message.save!

      if message.delivered_or_blocked?
        message.cleanup!
      else
        Nuntius::TransportRefreshJob.set(wait: message.refreshes + 5).perform_later(provider_name, message)
      end
    end
  end
end
