# frozen_string_literal: true

require 'messagebird'

module Nuntius
  # Send SMS messages using messagebird.com
  class MessageBirdSmsProvider < BaseProvider
    transport :sms

    setting_reader :auth_token, required: true, description: 'Authentication token'
    setting_reader :from, required: true, description: "Phone-number or name (say: 'Nuntius') to send the message from"

    # Messagebird statusses: scheduled, sent, buffered, delivered, expired, and delivery_failed.
    states %w[expired delivery_failed] => 'undelivered', 'delivered' => 'delivered'

    def deliver
      response = client.message_create(message.from || from, message.to, message.text)
      message.provider_id = response.id
      message.status = translated_status(response.recipients['items'].first.status)
      message
    end

    def refresh
      response = client.message(message.provider_id)
      message.provider_id = response.id
      message.status = translated_status(response.recipients['items'].first.status)
      Nuntius.logger.info "SMS #{message.to} status: #{message.status}"
      message
    rescue StandardError => _e
      message
    end

    private

    def client
      @client ||= ::MessageBird::Client.new(auth_token)
    end
  end
end
