# frozen_string_literal: true

module Nuntius
  # LMTP delivers actual email, so it shares all mail processing (premailer,
  # per-recipient splitting) with MailTransport. Only the configured providers
  # differ: the :lmtp transport routes to the LMTP provider.
  class LmtpTransport < MailTransport
  end
end
