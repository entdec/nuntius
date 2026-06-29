# frozen_string_literal: true

require "mail"

module Nuntius
  class SmtpMailProvider < BaseProvider
    transport :mail

    # RFC 5321 null reverse-path, used for auto-generated/bounce notifications.
    NULL_REVERSE_PATH = "<>"

    setting_reader :from_header, required: true, description: "From header (example: Nuntius Messenger <nuntius@entdec.com>)"
    setting_reader :host, required: true, description: "Host (example: smtp.soverin.net)"
    setting_reader :port, required: true, description: "Port (example: 578)"
    setting_reader :username, required: true, description: "Username (nuntius@entdec.com)"
    setting_reader :password, required: true, description: "Password"
    setting_reader :allow_list, required: false, default: [], description: "Allow list (example: [example.com, tim@apple.com])"
    setting_reader :ssl, required: false, default: false, description: "Whether to use SSL or not"

    def deliver
      return block unless MailAllowList.new(settings[:allow_list]).allowed?(message.to)
      return block if Nuntius::Message.where(status: %w[complaint bounced], to: message.to).count >= 1

      mail = if message.from.present?
        Mail.new(sender: from_header, from: message.from)
      else
        Mail.new(from: from_header)
      end

      null_sender = apply_mail_overrides(mail)

      if Rails.env.test?
        mail.delivery_method :test
      elsif null_sender
        mail.delivery_method Nuntius::NullSenderSmtp, smtp_settings
      else
        mail.delivery_method :smtp, smtp_settings
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
          message.html = message.html.gsub("{{message_url}}") { message_url(message) }
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

    # Applies any messenger-provided overrides stored on the message: extra
    # headers and/or a custom SMTP envelope sender. Returns true when a null
    # reverse-path (+MAIL FROM:<>+) was requested, so the caller can pick the
    # delivery method that can actually emit it.
    def apply_mail_overrides(mail)
      overrides = message.metadata&.dig("mail")
      return false if overrides.blank?

      (overrides["headers"] || {}).each do |key, value|
        mail.header[key] = value
      end

      return false unless overrides.key?("envelope_from")

      envelope_from = overrides["envelope_from"]
      if null_reverse_path?(envelope_from)
        mail.smtp_envelope_from = NULL_REVERSE_PATH
        true
      else
        mail.smtp_envelope_from = envelope_from
        false
      end
    end

    def null_reverse_path?(value)
      value.blank? || value == NULL_REVERSE_PATH
    end

    def message_url(message)
      Nuntius::Engine.routes.url_helpers.message_url(message.id, host: Nuntius.config.host(message))
    end
  end
end
