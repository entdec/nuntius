# frozen_string_literal: true

require "mail"

module Nuntius
  # Delivers mail to a mailbox over LMTP.
  #
  # The recipient and the per-message LMTP server are inline-encoded in the
  # message +to+ as <tt><email>@<host>:<port></tt> (for example
  # <tt>user@example.com@mx.internal:24</tt>). The +email+ is used for the
  # +To:+ header and the envelope +RCPT TO+; the +host:port+ is the LMTP
  # server we connect to. A plain address (without +@host:port+) falls back to
  # the configured +host+/+port+ settings.
  #
  # Delivery is synchronous: the server's per-recipient reply is the final
  # confirmation, so messages are marked +delivered+ directly and no refresh
  # job is required.
  class LmtpLmtpProvider < AbstractMailProvider
    transport :lmtp

    LMTP_TARGET = /\A(?<email>.+)@(?<host>[^@\s:]+):(?<port>\d+)\z/

    setting_reader :from_header, required: true, description: "From header (example: Nuntius Messenger <nuntius@entdec.com>)"
    setting_reader :host, required: false, default: nil, description: "Fallback LMTP host, used when not encoded in the recipient (example: 127.0.0.1)"
    setting_reader :port, required: false, default: nil, description: "Fallback LMTP port, used when not encoded in the recipient (example: 24)"
    setting_reader :allow_list, required: false, default: [], description: "Allow list (example: [example.com, tim@apple.com])"
    setting_reader :ssl, required: false, default: false, description: "Whether to use SSL or not"

    private

    def recipient
      lmtp_target[:email]
    end

    def prepare_envelope(mail)
      mail.smtp_envelope_to = recipient
    end

    def configure_delivery_method(mail, _null_sender)
      if Rails.env.test?
        mail.delivery_method :test
      else
        mail.delivery_method Nuntius::LmtpDeliveryMethod, lmtp_settings
      end
    end

    # LMTP delivery is synchronous and confirmed by the server, so we can mark
    # the message delivered straight away (no refresh job needed).
    def success_state
      :delivered
    end

    def lmtp_settings
      {
        address: lmtp_target[:host],
        port: lmtp_target[:port],
        ssl: ssl
      }
    end

    def lmtp_target
      @lmtp_target ||= begin
        match = message.to.to_s.strip.match(LMTP_TARGET)
        if match
          {email: match[:email], host: match[:host], port: match[:port].to_i}
        else
          {email: message.to, host: host, port: port}
        end
      end
    end
  end
end
