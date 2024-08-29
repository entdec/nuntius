# frozen_string_literal: true

require "smstools_api"

module Nuntius
  # Send SMS messages using smstools.nl
  class SmstoolsSmsProvider < BaseProvider
    transport :sms

    setting_reader :client_id, required: true, description: "Client ID"
    setting_reader :client_secret, required: true, description: "Client Secret"
    setting_reader :from, required: true, description: "Phone-number or name (example: 'Nuntius') to send the message from"

    # Twilio statusses: queued, failed, sent, delivered, or undelivered
    states %w[failed undelivered] => "undelivered", "delivered" => "delivered"

    def deliver
      response = client.messages.create(from: message.from.present? ? message.from : from, to: message.to, message: message.text)
      message.provider_id = response.sid
      message.status = translated_status(response.status)
      message
    end

    private

    def client
      @client ||= SmstoolsApi::Client.new(client_id: client_id, client_secret: client_secret)
    end
  end
end
