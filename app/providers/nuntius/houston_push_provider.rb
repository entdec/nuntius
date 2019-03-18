# frozen_string_literal: true

require 'houston'

module Nuntius
  class HoustonPushProvider < BaseProvider
    transport :push

    setting_reader :certificate,
                   required: true,
                   description: 'The contents of a valid APNS push certificate in .pem format'
    setting_reader :passphrase,
                   required: false,
                   description: 'If the APNS certificate is protected by a passphrase, ' +
                                'provide this variable to use when decrypting it.'
    setting_reader :environment,
                   required: false,
                   default: :production,
                   description: 'Development or production, defaults to production'

    def deliver
      return message if message.to.size != 64

      apn = environment.to_sym == :development ? Houston::Client.development : Houston::Client.production
      apn.certificate = certificate
      apn.passphrase = passphrase

      notification = Houston::Notification.new((message.payload || {}).merge(device: message.to,
                                                                             alert: message.text, sound: 'default'))
      apn.push(notification)

      message.status = if notification.sent?
                         'sending'
                       elsif !notification.valid? || notification.error
                         'undelivered'
                       end
      message
    end

  end
end
