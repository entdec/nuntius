# frozen_string_literal: true

module Nuntius
  class SmsTransport < BaseTransport

    def send(message)
      # Try each driver in turn until message is delivered
      # Use timeout, break if delivered
      priority = 1
      while (drivers_for_prio = drivers(priority)).present?
        drivers_for_prio.each do |driver|
          message = driver.send(message)

          # If the message is still draft, the driver did not act on it
          message.save! unless message.draft?

          # We stop at the first driver which delivered the message
          break if message.delivered?
        end

        # Don't check other priority drivers if we delivered
        break if message.delivered?

        priority += 1
      end
    end

    def kind
      :sms
    end
  end
end
