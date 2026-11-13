# frozen_string_literal: true

require "mail"

module Nuntius
  # Delivers mail to a mailbox over LMTP.
  #
  # It takes the mail to LMTP addresses (see LmtpAddress): the recipient and
  # the LMTP server are inline-encoded in the message +to+ as
  # <tt><email>@<host>:<port></tt> (for example
  # <tt>user@example.com@mx.internal:24</tt>). The +email+ is used for the
  # +To:+ header and the envelope +RCPT TO+; the +host:port+ is the LMTP
  # server we connect to. Other mail goes to SMTP.
  #
  # Delivery is synchronous: the server's per-recipient reply is the final
  # confirmation, so messages are marked +delivered+ directly and no refresh
  # job is required.
  class LmtpMailProvider < AbstractMailProvider
    transport :mail

    setting_reader :from_header, required: true, description: "From header (example: Nuntius Messenger <nuntius@example.com>)"
    setting_reader :allow_list, required: false, default: [], description: "Allow list (example: [example.com, someone@example.org])"
    setting_reader :ssl, required: false, default: false, description: "Whether to use SSL or not"

    def self.handles?(to)
      LmtpAddress.match?(to)
    end

    private

    def recipient
      lmtp_address&.email
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
        address: lmtp_address.host,
        port: lmtp_address.port,
        ssl: ssl
      }
    end

    def lmtp_address
      @lmtp_address ||= LmtpAddress.parse(message.to)
    end
  end
end
