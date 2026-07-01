# frozen_string_literal: true

require "test_helper"
require "socket"

module Nuntius
  class LmtpDeliveryMethodTest < ActiveSupport::TestCase
    test "performs the LMTP conversation and returns a successful response" do
      received = []
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]

      server_thread = Thread.new do
        client = server.accept
        client.print "220 lmtp ready\r\n"
        received << client.gets # LHLO
        client.print "250-lmtp greets you\r\n250 PIPELINING\r\n"
        received << client.gets # MAIL FROM
        client.print "250 2.1.0 Ok\r\n"
        received << client.gets # RCPT TO
        client.print "250 2.1.5 Ok\r\n"
        received << client.gets # DATA
        client.print "354 End data with <CR><LF>.<CR><LF>\r\n"
        loop do
          line = client.gets
          break if line.nil? || line == ".\r\n"
        end
        client.print "250 2.0.0 <user@example.com> delivered\r\n"
        received << client.gets # QUIT
        client.print "221 2.0.0 Bye\r\n"
        client.close
      ensure
        server.close
      end

      response = Nuntius::LmtpDeliveryMethod.new(address: "127.0.0.1", port: port, domain: "test.local").deliver!(build_mail)
      server_thread.join(2)

      assert response.success?
      assert_equal "LHLO test.local\r\n", received[0]
      assert_equal "MAIL FROM:<from@example.com>\r\n", received[1]
      assert_equal "RCPT TO:<user@example.com>\r\n", received[2]
      assert_equal "DATA\r\n", received[3]
      assert_equal "QUIT\r\n", received[4]
    end

    test "raises Net::SMTPFatalError on a 5xx reply" do
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]

      server_thread = Thread.new do
        client = server.accept
        client.print "220 lmtp ready\r\n"
        client.gets # LHLO
        client.print "250 lmtp\r\n"
        client.gets # MAIL FROM
        client.print "550 5.1.0 Sender rejected\r\n"
        client.close
      ensure
        server.close
      end

      method = Nuntius::LmtpDeliveryMethod.new(address: "127.0.0.1", port: port)

      assert_raises(Net::SMTPFatalError) do
        method.deliver!(build_mail)
      end

      server_thread.join(2)
    end

    private

    def build_mail
      mail = Mail.new do
        from "from@example.com"
        to "user@example.com"
        subject "Hi"
        body "Hello there"
      end
      mail.smtp_envelope_from = "from@example.com"
      mail.smtp_envelope_to = "user@example.com"
      mail
    end
  end
end
