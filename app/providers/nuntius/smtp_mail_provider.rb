# frozen_string_literal: true

require "mail"

module Nuntius
  class SmtpMailProvider < AbstractMailProvider
    transport :mail

    setting_reader :from_header, required: true, description: "From header (example: Nuntius Messenger <nuntius@entdec.com>)"
    setting_reader :host, required: true, description: "Host (example: smtp.soverin.net)"
    setting_reader :port, required: true, description: "Port (example: 578)"
    setting_reader :username, required: true, description: "Username (nuntius@entdec.com)"
    setting_reader :password, required: true, description: "Password"
    setting_reader :allow_list, required: false, default: [], description: "Allow list (example: [example.com, tim@apple.com])"
    setting_reader :ssl, required: false, default: false, description: "Whether to use SSL or not"

    private

    def configure_delivery_method(mail, null_sender)
      if Rails.env.test?
        mail.delivery_method :test
      elsif null_sender
        mail.delivery_method Nuntius::NullSenderSmtp, smtp_settings
      else
        mail.delivery_method :smtp, smtp_settings
      end
    end

    def smtp_settings
      {
        address: host,
        port: port,
        user_name: username,
        password: password,
        return_response: true,
        ssl: ssl
      }
    end
  end
end
