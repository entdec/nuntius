# frozen_string_literal: true

require "test_helper"

module Nuntius
  class LmtpLmtpProviderTest < ActiveSupport::TestCase
    setup do
      Mail::TestMailer.deliveries.clear
    end

    test "parses the inline <email>@<host>:<port> recipient" do
      provider = Nuntius::LmtpLmtpProvider.new(build_message(to: "user@example.com@mx.internal:24"))

      target = provider.send(:lmtp_target)
      assert_equal "user@example.com", target[:email]
      assert_equal "mx.internal", target[:host]
      assert_equal 24, target[:port]
    end

    test "delivers to the email address while routing to the inline server" do
      message = build_message(to: "user@example.com@mx.internal:24")

      Nuntius::LmtpLmtpProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_equal ["user@example.com"], mail.to
      assert_equal ["user@example.com"], mail.smtp_envelope_to
    end

    test "marks the message delivered immediately (no refresh job needed)" do
      message = build_message(to: "user@example.com@mx.internal:24")

      Nuntius::LmtpLmtpProvider.new(message).deliver

      assert message.delivered?
      refute message.sent?
    end

    test "falls back to the configured host/port for a plain address" do
      provider = Nuntius::LmtpLmtpProvider.new(build_message(to: "user@example.com"))

      provider.stub(:host, "127.0.0.1") do
        provider.stub(:port, 24) do
          target = provider.send(:lmtp_target)
          assert_equal "user@example.com", target[:email]
          assert_equal "127.0.0.1", target[:host]
          assert_equal 24, target[:port]
        end
      end
    end

    test "blocks a recipient that is not on the allow list" do
      message = build_message(to: "user@blocked.test@mx.internal:24")

      Nuntius::LmtpLmtpProvider.new(message).deliver

      assert message.blocked?
      assert_equal 0, Mail::TestMailer.deliveries.length
    end

    test "blocks a recipient that previously bounced" do
      Nuntius::Message.create!(transport: "lmtp", to: "bouncer@example.com", html: "x", text: "x", state: "bounced")
      message = build_message(to: "bouncer@example.com@mx.internal:24")

      Nuntius::LmtpLmtpProvider.new(message).deliver

      assert message.blocked?
      assert_equal 0, Mail::TestMailer.deliveries.length
    end

    private

    def build_message(to:, metadata: {})
      Nuntius::Message.new(
        transport: "lmtp",
        provider: "lmtp",
        to: to,
        subject: "Test",
        text: "Body",
        metadata: metadata
      )
    end
  end
end
