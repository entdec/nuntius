# frozen_string_literal: true

require "mail"

module Nuntius
  # Shared delivery flow for mail providers (SMTP, LMTP). Concrete providers
  # supply the recipient, the delivery method and the success semantics through
  # the hooks below.
  class AbstractMailProvider < BaseProvider
    transport :mail

    # RFC 5321 null reverse-path, used for auto-generated/bounce notifications.
    NULL_REVERSE_PATH = "<>"

    def deliver
      return no_recipient if recipient.blank?
      return block unless MailAllowList.new(settings[:allow_list]).allowed?(recipient)
      return block if Nuntius::Message.where(state: %w[complaint bounced], to: recipient).count >= 1

      mail = if message.from.present?
        Mail.new(sender: from_header, from: message.from)
      else
        Mail.new(from: from_header)
      end

      mail.header["X-Nuntius-Message-Id"] = message.id

      if message.campaign.present? && message.subscriber.present?
        mail.header["List-Unsubscribe"] = "<" + message.subscriber.unsubscribe_link(message.campaign, message) + ">"
        mail.header["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
      end

      null_sender = apply_mail_overrides(mail)

      configure_delivery_method(mail, null_sender)

      mail.to = recipient
      mail.subject = message.subject
      mail.part content_type: "multipart/alternative" do |p|
        p.text_part = Mail::Part.new(
          body: message.text,
          content_type: "text/plain",
          charset: "UTF-8"
        )
        if message.html.present?
          # Apply email tracking (tracking pixel and link wrapping)
          Nuntius::EmailTrackingService.perform(message: message)

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

      prepare_envelope(mail)

      begin
        response = mail.deliver!
      rescue Net::SMTPFatalError
        message.rejected
        return message
      rescue Net::SMTPServerBusy, Net::ReadTimeout
        message.undelivered
        return message
      end

      message.provider_id = mail.message_id
      message.undelivered
      message.send(success_state) if Rails.env.test? || delivered_successfully?(response)
      message.last_sent_at = Time.zone.now if message.sent? || message.delivered?

      message
    end

    def block
      message.blocked
      message
    end

    def no_recipient
      message.no_recipient
      message
    end

    private

    # The resolved recipient email address. Used for the blank check, allow
    # list, bounce dedup query and the +To:+ header. Subclasses may override
    # (e.g. LMTP parses it out of the inline +to+).
    def recipient
      message.to
    end

    # Hook to set a custom SMTP/LMTP envelope. Default lets Mail derive it.
    def prepare_envelope(mail)
    end

    # Concrete providers must configure how +mail+ is delivered.
    def configure_delivery_method(mail, null_sender)
      raise NotImplementedError, "#{self.class} must implement #configure_delivery_method"
    end

    # Whether a non-test delivery response counts as success.
    def delivered_successfully?(response)
      response.success?
    end

    # State to transition to on a successful delivery.
    def success_state
      :sent
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
