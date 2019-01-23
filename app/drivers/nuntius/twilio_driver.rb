# frozen_string_literal: true

require 'twilio-ruby'

module Nuntius
  # Send SMS messages using twilio.com
  class TwilioDriver < BaseDriver
    adapter :sms

    setting_reader :auth_token, required: true, description: 'Authentication token'
    setting_reader :sid, required: true, description: 'Application SID, see Twilio console'
    setting_reader :from, required: true, description: "Phone-number or name (say: 'Nuntius') to send the message from"

    # Twilio statusses: queued, failed, sent, delivered, or undelivered
    states %w[failed undelivered] => 'undelivered', 'delivered' => 'delivered'

    def send(message)
      response = client.messages.create(from: message.from, to: message.to, body: message.text)
      message.driver_id = response.sid
      message.status = translated_status(response.status)
      message
    end

    def refresh(message)
      response = client.messages(message.driver_id).fetch
      message.driver_id = response.sid
      message.status = translated_status(response.status)
      message
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(sid, auth_token)
    end

  end
end
