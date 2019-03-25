# frozen_string_literal: true

require 'twilio-ruby'

module Nuntius
  # Send Voice call messages using twilio.com
  class TwilioVoiceProvider < BaseProvider
    transport :voice

    setting_reader :host, required: true, description: 'Host or base-url for the application'
    setting_reader :auth_token, required: true, description: 'Authentication token'
    setting_reader :sid, required: true, description: 'Application SID, see Twilio console'
    setting_reader :from, required: true, description: "Phone-number or name (example: 'Nuntius') to send the message from"

    # Twilio statusses: queued, failed, sent, delivered, or undelivered
    states %w[failed undelivered] => 'undelivered', %w[delivered completed] => 'delivered'

    def deliver
      # Need hostname here too
      response = client.calls.create(from: message.from || from, to: message.to, method: 'POST', url: callback_url)
      message.provider_id = response.sid
      message.status = translated_status(response.status)
      message
    end

    def refresh
      response = client.calls(message.provider_id).fetch
      message.provider_id = response.sid
      message.status = translated_status(response.status)
      message
    end

    def callback(params)
      refresh.save

      twiml = script_for_path(message, "/#{params[:path]}", params)

      if twiml
        [200, { 'Content-Type' => 'application/xml' }, [twiml[:body]]]
      else
        [404, { 'Content-Type' => 'text/html; charset=utf-8' }, ['Not found']]
      end
    end

    private

    def client
      @client ||= Twilio::REST::Client.new(sid, auth_token)
    end

    def script_for_path(message, path = '/', params)
      scripts = message.text.delete("\r").split("\n\n")

      scripts = scripts.map do |script|
        preamble = Preamble.parse(script)
        payload = preamble.metadata ? payload = preamble.content : script
        payload = payload.gsub('{{url}}', callback_url)
        metadata = preamble.metadata || { path: '/' }

        { headers: metadata.with_indifferent_access, body: payload }
      end

      scripts.find { |s| s[:headers][:path] == path }
    end

    def callback_url
      Nuntius::Engine.routes.url_helpers.callback_url(message.id, host: host)
    end
  end
end
