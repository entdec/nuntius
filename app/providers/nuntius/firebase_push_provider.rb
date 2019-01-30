# frozen_string_literal: true

require 'fcm'

module Nuntius
  class FirebasePushProvider < BaseProvider
    transport :push

    setting_reader :server_key, required: true, description: 'Server key for the project, see Firebase console'

    def deliver(message)
      fcm = FCM.new(server_key)

      options = { data: { body: message.text } }
      response = fcm.send([message.to], options)

      message.status = if response[:status_code] != 200 || response[:response] != 'success'
                         'undelivered'
                       else
                         'sending'
                       end

      message
    end

  end
end
