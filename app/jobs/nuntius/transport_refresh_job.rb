# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class TransportRefreshJob < ApplicationJob
    queue_as Nuntius.config.jobs_queue_name

    def perform(provider_name, message)
      return if message.delivered? || message.refreshes >= 3

      provider = BaseProvider.class_from_name(provider_name, message.transport).new(message)
      message = provider.refresh
      # FIXME: This may need to be more atomic
      message.refreshes += 1
      message.save! unless message.pending?

      if message.delivered?
        message.cleanup!
      else
        TransportRefreshJob.set(wait: message.refreshes + 5).perform_later(provider_name, message)
      end
    end
  end
end
