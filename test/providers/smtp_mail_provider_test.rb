# frozen_string_literal: true

require "test_helper"

module Nuntius
  class SmtpMailProviderTest < ActiveSupport::TestCase
    setup do
      Mail::TestMailer.deliveries.clear
    end

    test "applies messenger-provided headers to the delivered mail" do
      message = build_message(metadata: {
        "mail" => {"headers" => {"Auto-Submitted" => "auto-replied", "Precedence" => "bulk"}}
      })

      Nuntius::SmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_equal "auto-replied", mail["Auto-Submitted"].value
      assert_equal "bulk", mail["Precedence"].value
    end

    test "uses a null reverse-path when a null envelope sender is requested" do
      message = build_message(metadata: {"mail" => {"envelope_from" => "<>"}})

      Nuntius::SmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_equal "<>", mail.smtp_envelope_from
    end

    test "applies a custom (non-null) envelope sender when requested" do
      message = build_message(metadata: {"mail" => {"envelope_from" => "bounce@example.com"}})

      Nuntius::SmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_equal "bounce@example.com", mail.smtp_envelope_from
    end

    test "does not add overrides for a regular message" do
      message = build_message

      Nuntius::SmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_nil mail["Auto-Submitted"]
      refute_equal "<>", mail.smtp_envelope_from
    end

    private

    def build_message(metadata: {})
      Nuntius::Message.new(
        transport: "mail",
        provider: "smtp",
        to: "user@example.com",
        subject: "Test",
        text: "Body",
        metadata: metadata
      )
    end
  end
end
