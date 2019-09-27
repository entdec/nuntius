# frozen_string_literal: true

require 'slack'

module Nuntius
  class SlackSlackProvider < BaseProvider
    transport :slack

    setting_reader :api_key, required: true, description: 'API key for the Slack workspace'

    def deliver
      client = Slack::Web::Client.new(key: api_key)

      message.attachments.each do |attachment|
        client.files_upload(
          channels: message[:to],
          as_user: true,
          username: message[:from],
          file: Faraday::UploadIO.new(StringIO.new(attachment.download), attachment.content_type),
          filename: attachment.filename.to_s
        )
      end

      args = (message.payload || {}).merge(channel: message[:to], text: message.text, as_user: true, username: message[:from])
      response = client.chat_postMessage(args.deep_symbolize_keys)

      message.status = if response['ok']
                         'sent'
                       else
                         'undelivered'
                       end

      message
    end
  end
end
