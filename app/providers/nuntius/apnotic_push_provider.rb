# frozen_string_literal: true

require "apnotic"

module Nuntius
  class ApnoticPushProvider < BaseProvider
    transport :push

    setting_reader :certificate,
      required: true,
      description: "The contents of a valid APNS push certificate in .pem format"
    setting_reader :passphrase,
      required: false,
      description: "If the APNS certificate is protected by a passphrase, " \
                   "provide this variable to use when decrypting it."
    setting_reader :environment,
      required: false,
      default: :production,
      description: "Development or production, defaults to production"

    def deliver
      return message if message.to.size != 64

      connection = if environment.to_sym == :development
        Apnotic::Connection.development(cert_path: StringIO.new(certificate), cert_pass: passphrase)
      else
        Apnotic::Connection.new(cert_path: StringIO.new(certificate), cert_pass: passphrase)
      end

      notification = Apnotic::Notification.new(message.to)
      notification.alert = message.text
      notification.custom_payload = message.payload

      response = connection.push(notification)

      message.status = if response.ok?
        "sent"
      else
        "undelivered"
      end
      message
    end
  end
end
