# frozen_string_literal: true

require 'slack'

module Nuntius
  class SlackSlackProvider < BaseProvider
    transport :slack

    setting_reader :api_key, required: true, description: 'API key for the Slack workspace'

    def deliver
      client = Slack::Web::Client.new(key: api_key)

      response = client.chat_postMessage(channel: message[:to], text: message.text, as_user: true)

      message.status = if response["ok"]
                         'sent'
                       else
                         'undelivered'
                       end

      message
    end

  end
end
