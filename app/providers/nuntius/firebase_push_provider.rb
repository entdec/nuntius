# frozen_string_literal: true

require "fcm"

module Nuntius
  class FirebasePushProvider < BaseProvider
    transport :push

    setting_reader :server_key, required: true, description: "Server key for the project, see Firebase console"

    def deliver
      fcm = FCM.new(server_key)

      options = (message.payload || {}).merge(data: {body: message.text})
      response = fcm.send([message.to], options)

      message.status = if response[:status_code] != 200 || response[:response] != "success"
        "undelivered"
      else
        "sent"
      end

      message
    end
  end
end
