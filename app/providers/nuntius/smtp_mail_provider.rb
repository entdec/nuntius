# frozen_string_literal: true

require "mail"

module Nuntius
  class SmtpMailProvider < BaseProvider
    transport :mail

    setting_reader :from_header, required: true, description: "From header (example: Nuntius Messenger <nuntius@entdec.com>)"
    setting_reader :host, required: true, description: "Host (example: smtp.soverin.net)"
    setting_reader :port, required: true, description: "Port (example: 578)"
    setting_reader :username, required: true, description: "Username (nuntius@entdec.com)"
    setting_reader :password, required: true, description: "Password"
    setting_reader :allow_list, required: false, default: [], description: "Allow list (example: [boxture.com, tom@degrunt.net])"

    def deliver
      return block unless MailAllowList.new(settings[:allow_list]).allowed?(message.to)
      return block if Nuntius::Message.where(status: %w[complaint bounced], to: message.to).count >= 1

      mail = if message.from.present?
        Mail.new(sender: from_header, from: message.from)
      else
        Mail.new(from: from_header)
      end

      if Rails.env.test?
        mail.delivery_method :test
      else
        mail.delivery_method :smtp,
          address: host,
          port: port,
          user_name: username,
          password: password,
          return_response: true
      end

      mail.to = message.to
      mail.subject = message.subject
      mail.part content_type: "multipart/alternative" do |p|
        p.text_part = Mail::Part.new(
          body: message.text,
          content_type: "text/plain",
          charset: "UTF-8"
        )
        if message.html.present?
          message.html = message.html.gsub("%7B%7Bmessage_url%7D%7D") { message_url(message) }
          p.html_part = Mail::Part.new(
            body: message.html,
            content_type: "text/html",
            charset: "UTF-8"
          )
        end
      end

      message.attachments.each do |attachment|
        mail.attachments[attachment.filename.to_s] = {mime_type: attachment.content_type, content: attachment.download}
      end

      begin
        response = mail.deliver!
      rescue Net::SMTPFatalError
        message.status = "rejected"
        return message
      rescue Net::SMTPServerBusy, Net::ReadTimeout
        message.status = "undelivered"
        return message
      end

      message.provider_id = mail.message_id
      message.status = "undelivered"
      message.status = "sent" if Rails.env.test? ? true : response.success?
      message.last_sent_at = Time.zone.now if message.sent?

      message
    end

    def block
      message.status = "blocked"
      message
    end

    private

    def message_url(message)
      Nuntius::Engine.routes.url_helpers.message_url(message.id, host: Nuntius.config.host(message))
    end
  end
end
