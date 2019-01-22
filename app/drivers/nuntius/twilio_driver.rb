# frozen_string_literal: true

require 'twilio-ruby'

module Nuntius
  class TwilioDriver < BaseDriver
    adapter :push

    setting_reader :auth_token, required: true, description: 'Authentication token'
    setting_reader :sid, required: true, description: 'Application SID, see Twilio console'
    setting_reader :from, required: true, description: "Phone-number or name (say: 'Nuntius') to send the message from"

    def send(message)
      response = client.messages.create(from: message.from, to: message.to, body: message.text)
      message.driver_id = response.sid
      message.status = response.status
      message
    end

    def refresh(message)
      response = client.messages(message.driver_id).fetch
      message.driver_id = response.sid
      message.status = response.status
      message
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(sid, auth_token)
    end

  end
end
