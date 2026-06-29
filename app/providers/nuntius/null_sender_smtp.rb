# frozen_string_literal: true

require "mail"

module Nuntius
  # A Mail::SMTP delivery method that sends with a null reverse-path
  # (+MAIL FROM:<>+).
  #
  # The stock Mail::SmtpEnvelope refuses to emit an empty reverse-path
  # (it raises on a blank From), and Net::SMTP wraps the address in angle
  # brackets, so setting +smtp_envelope_from+ to +"<>"+ would produce the
  # invalid +MAIL FROM:<<>>+. This delivery method bypasses Mail::SmtpEnvelope
  # and hands an empty reverse-path straight to Net::SMTP, yielding the
  # RFC 5321 null sender used by auto-generated/bounce notifications.
  class NullSenderSmtp < ::Mail::SMTP
    def deliver!(mail)
      response = start_smtp_session do |smtp|
        smtp.sendmail(mail.encoded, "", mail.smtp_envelope_to)
      end

      settings[:return_response] ? response : self
    end
  end
end
