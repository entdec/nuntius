# frozen_string_literal: true

require 'houston'

module Nuntius
  class HoustonProvider < BaseProvider
    transport :push

    # html, text, attachments

    def deliver(to, text)
      apn = Rails.env.production? ? Houston::Client.production : Houston::Client.development
      apn.certificate = ios_config['certificate'] + "\n" + ios_config['key']

      body = "#{environment_string}#{tpl(:text, obj, context)}"

      to.uniq!
      to.each do |token|
        notification = Houston::Notification.new(device: token)
        notification.alert = body
        notification.badge = 0
        notification.sound = 'default'
        apn.push(notification)
      end
    end

  end
end
