# frozen_string_literal: true

require 'fcm'

module Nuntius
  class FirebaseDriver < BaseDriver
    adapter :push

    def send(to, text)
      body = "#{environment_string}#{tpl(:text, obj, context)}"

      # See https://console.firebase.google.com/project/<project>/settings/cloudmessaging
      fcm = FCM.new(android_config['server_key'])

      if android_devices.present?
        options = { data: { body: body } }
        response = fcm.send(android_devices, options)
        raise "FCM said: #{response[:status_code]} / #{response[:response]}" if response[:status_code] != 200 || response[:response] != 'success'
      end
    end

  end
end
