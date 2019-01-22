# frozen_string_literal: true

require 'messagebird'

module Nuntius
  class MessageBirdDriver < BaseDriver
    adapter :push

    setting_reader :auth_token, required: true, description: 'Authentication token'
    setting_reader :from, required: true, description: "Phone-number or name (say: 'Nuntius') to send the message from"

    def send(message)
      response = client.message_create(message.from, message.to, message.text)
      message.driver_id = response.id
      message.status = response.recipients['items'].first.status
      message
    end

    def refresh(message)
      response = client.message(message.driver_id)
      message.driver_id = response.id
      message.status = response.recipients['items'].first.status
      message
      Nuntius.logger.info "SMS #{message.to} status: #{status}"
    rescue StandardError => _e
      message
    end

    private

    def client
      @client ||= ::MessageBird::Client.new(auth_token)
    end
  end
end
