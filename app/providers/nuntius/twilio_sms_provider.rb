# frozen_string_literal: true

require 'twilio-ruby'

module Nuntius
  # Send SMS messages using twilio.com
  class TwilioSmsProvider < BaseProvider
    transport :sms

    setting_reader :auth_token, required: true, description: 'Authentication token'
    setting_reader :sid, required: true, description: 'Application SID, see Twilio console'
    setting_reader :from, required: true, description: "Phone-number or name (example: 'Nuntius') to send the message from"

    # Twilio statusses: queued, failed, sent, delivered, or undelivered
    states %w[failed undelivered] => 'undelivered', 'delivered' => 'delivered'

    def deliver
      response = client.messages.create(from: message.from.present? ? message.from : from, to: message.to, body: message.text)
      message.provider_id = response.sid
      message.status = translated_status(response.status)
      message
    end

    def refresh
      response = client.messages(message.provider_id).fetch
      message.provider_id = response.sid
      message.status = translated_status(response.status)
      message
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(sid, auth_token)
    end

  end
end
