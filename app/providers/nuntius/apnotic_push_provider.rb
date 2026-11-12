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

    # APNs device tokens: 64 hexadecimal characters
    TOKEN = /\A\h{64}\z/

    # Other push tokens go to Firebase
    def self.handles?(to)
      TOKEN.match?(to.to_s)
    end

    def deliver
      return message unless self.class.handles?(message.to)

      connection = if environment.to_sym == :development
        Apnotic::Connection.development(cert_path: StringIO.new(certificate), cert_pass: passphrase)
      else
        Apnotic::Connection.new(cert_path: StringIO.new(certificate), cert_pass: passphrase)
      end

      notification = Apnotic::Notification.new(message.to)
      notification.alert = message.text
      notification.custom_payload = message.payload

      response = connection.push(notification)

      if response.ok?
        message.sent
      else
        message.undelivered
      end
      message
    end
  end
end
