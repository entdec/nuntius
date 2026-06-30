# frozen_string_literal: true

require "socket"
require "openssl"
require "net/smtp"

module Nuntius
  # A minimal LMTP (RFC 2033) delivery method, usable as a Mail delivery
  # method (+initialize(settings)+ + +deliver!(mail)+).
  #
  # Net::SMTP / Mail::SMTP greet with +EHLO+/+HELO+, but LMTP requires +LHLO+
  # and returns one reply per recipient after the message body, so we speak the
  # protocol directly over a socket. Failures raise the same Net::SMTP errors
  # SMTP delivery would, so callers can treat both transports identically.
  class LmtpDeliveryMethod
    Response = Struct.new(:code, :message) do
      def success?
        code.to_s.start_with?("2")
      end
    end

    DEFAULTS = {
      address: "localhost",
      port: 24,
      ssl: false,
      domain: "localhost"
    }.freeze

    attr_reader :settings

    def initialize(settings = {})
      @settings = DEFAULTS.merge(settings.compact)
    end

    def deliver!(mail)
      envelope_from = mail.smtp_envelope_from
      destinations = Array(mail.smtp_envelope_to)
      raise ArgumentError, "LMTP delivery requires at least one recipient" if destinations.empty?

      data = mail.encoded
      socket = open_socket
      begin
        read_reply(socket, expected: "2") # 220 greeting
        send_command(socket, "LHLO #{settings[:domain]}", expected: "2")
        send_command(socket, "MAIL FROM:<#{envelope_from}>", expected: "2")
        destinations.each do |to|
          send_command(socket, "RCPT TO:<#{to}>", expected: "2")
        end

        send_command(socket, "DATA", expected: "3") # 354
        socket.write(dot_stuff(data))
        socket.write("\r\n") unless data.end_with?("\r\n")
        socket.write(".\r\n")

        # LMTP returns one reply per recipient after the body.
        response = nil
        destinations.each do
          response = read_reply(socket, expected: "2")
        end

        send_command(socket, "QUIT", expected: nil)
        response
      ensure
        socket.close unless socket.closed?
      end
    end

    private

    def open_socket
      tcp = TCPSocket.open(settings[:address], settings[:port])
      return tcp unless settings[:ssl]

      ssl = OpenSSL::SSL::SSLSocket.new(tcp)
      ssl.sync_close = true
      ssl.connect
      ssl
    end

    def send_command(socket, command, expected:)
      socket.write("#{command}\r\n")
      read_reply(socket, expected: expected)
    end

    def read_reply(socket, expected:)
      lines = []
      code = nil
      loop do
        line = socket.gets
        raise Net::SMTPFatalError, "LMTP connection closed unexpectedly" if line.nil?

        line = line.chomp
        lines << line
        code = line[0, 3]
        # Multiline replies use "250-..." for every line but the last ("250 ...").
        break unless line[3] == "-"
      end

      response = Response.new(code, lines.join("\n"))
      return response if expected.nil? || code.to_s.start_with?(expected)

      raise_for(code, response.message)
    end

    def raise_for(code, message)
      case code.to_s[0]
      when "4"
        raise Net::SMTPServerBusy, message
      when "5"
        raise Net::SMTPFatalError, message
      else
        raise Net::SMTPUnknownError, message
      end
    end

    # RFC 5321 transparency: lines starting with a dot get an extra dot.
    def dot_stuff(data)
      data.gsub(/^\./, "..")
    end
  end
end
