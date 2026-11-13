# frozen_string_literal: true

require "test_helper"

module Nuntius
  class LmtpMailProviderTest < ActiveSupport::TestCase
    setup do
      Mail::TestMailer.deliveries.clear
    end

    test "parses the inline <email>@<host>:<port> recipient" do
      address = Nuntius::LmtpAddress.parse(" user@example.com@mx.internal:24 ")

      assert_equal "user@example.com", address.email
      assert_equal "mx.internal", address.host
      assert_equal 24, address.port
      assert_nil Nuntius::LmtpAddress.parse("user@example.com")
    end

    test "handles LMTP addresses, and SMTP the other mail" do
      assert Nuntius::LmtpMailProvider.handles?("user@example.com@mx.internal:24")
      refute Nuntius::LmtpMailProvider.handles?("user@example.com")
      refute Nuntius::SmtpMailProvider.handles?("user@example.com@mx.internal:24")
      assert Nuntius::SmtpMailProvider.handles?("user@example.com")
    end

    test "delivers to the email address while routing to the inline server" do
      message = build_message(to: "user@example.com@mx.internal:24")

      Nuntius::LmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_equal ["user@example.com"], mail.to
      assert_equal ["user@example.com"], mail.smtp_envelope_to
    end

    test "marks the message delivered immediately (no refresh job needed)" do
      message = build_message(to: "user@example.com@mx.internal:24")

      Nuntius::LmtpMailProvider.new(message).deliver

      assert message.delivered?
      refute message.sent?
    end

    test "has no recipient without an LMTP address" do
      message = build_message(to: "user@example.com")

      Nuntius::LmtpMailProvider.new(message).deliver

      assert message.no_recipient?
      assert_equal 0, Mail::TestMailer.deliveries.length
    end

    test "blocks a recipient that is not on the allow list" do
      message = build_message(to: "user@blocked.test@mx.internal:24")

      Nuntius::LmtpMailProvider.new(message).deliver

      assert message.blocked?
      assert_equal 0, Mail::TestMailer.deliveries.length
    end

    test "blocks a recipient that previously bounced" do
      Nuntius::Message.create!(transport: "mail", to: "bouncer@example.com", html: "x", text: "x", state: "bounced")
      message = build_message(to: "bouncer@example.com@mx.internal:24")

      Nuntius::LmtpMailProvider.new(message).deliver

      assert message.blocked?
      assert_equal 0, Mail::TestMailer.deliveries.length
    end

    private

    def build_message(to:, **attributes)
      Nuntius::Message.new(
        transport: "mail",
        provider: "lmtp",
        to: to,
        subject: "Test",
        text: "Body",
        **attributes
      )
    end
  end
end
