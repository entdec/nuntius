# frozen_string_literal: true

module Nuntius
  # An address for delivery over LMTP: the recipient's email together with the
  # LMTP server to deliver it to, as <tt><email>@<host>:<port></tt> (for
  # example <tt>user@example.com@mx.internal:24</tt>). Mail to such an address
  # goes to the LMTP provider, other mail to SMTP (see BaseProvider.handles?).
  class LmtpAddress
    PATTERN = /\A(?<email>.+)@(?<host>[^@\s:]+):(?<port>\d+)\z/

    attr_reader :email, :host, :port

    # The LMTP address in +address+, or nil when it isn't one
    def self.parse(address)
      match = address.to_s.strip.match(PATTERN)
      new(match[:email], match[:host], match[:port].to_i) if match
    end

    def self.match?(address)
      PATTERN.match?(address.to_s.strip)
    end

    def initialize(email, host, port)
      @email = email
      @host = host
      @port = port
    end
  end
end
