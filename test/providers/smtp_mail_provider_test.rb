# frozen_string_literal: true

require "test_helper"

module Nuntius
  class SmtpMailProviderTest < ActiveSupport::TestCase
    setup do
      Mail::TestMailer.deliveries.clear
    end

    test "applies messenger-provided headers to the delivered mail" do
      message = build_message(headers: {"Auto-Submitted" => "auto-replied", "Precedence" => "bulk"})

      Nuntius::SmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_equal "auto-replied", mail["Auto-Submitted"].value
      assert_equal "bulk", mail["Precedence"].value
    end

    test "sends the message id as Lettermint metadata when Lettermint's webhook is set up" do
      original = Nuntius.config.lettermint_webhook_settings
      Nuntius.config.lettermint_webhook(api_token: "token", project_id: "project", setup_on_boot: false)
      message = build_message
      message.id = SecureRandom.uuid

      Nuntius::SmtpMailProvider.new(message).deliver

      assert_equal message.id, Mail::TestMailer.deliveries.last["X-LM-Metadata-nuntius_message_id"].value
    ensure
      Nuntius.config.instance_variable_set(:@lettermint_webhook_settings, original)
    end

    test "sends no Lettermint metadata without Lettermint's webhook" do
      Nuntius::SmtpMailProvider.new(build_message).deliver

      assert_nil Mail::TestMailer.deliveries.last["X-LM-Metadata-nuntius_message_id"]
    end

    test "uses a null reverse-path when a null envelope sender is requested" do
      message = build_message(envelope_from: "<>")

      Nuntius::SmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      assert_equal "<>", mail.smtp_envelope_from
    end

    test "applies a custom (non-null) envelope sender when requested" do
      message = build_message(envelope_from: "bounce@example.com")

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

    test "marks a delivered message sent" do
      message = build_message

      Nuntius::SmtpMailProvider.new(message).deliver

      assert_equal "sent", message.state
      assert_equal Mail::TestMailer.deliveries.last.message_id, message.provider_id
      assert message.last_sent_at.present?
    end

    test "marks a message without recipient no_recipient" do
      message = build_message(to: "")

      Nuntius::SmtpMailProvider.new(message).deliver

      assert_equal "no_recipient", message.state
      assert_empty Mail::TestMailer.deliveries
    end

    test "marks a message rejected by the server rejected" do
      message = build_message

      deliver_raising(message, Net::SMTPFatalError.new("550 The sending domain example.com is not verified"))

      assert_equal "rejected", message.state
      assert_nil message.provider_id
    end

    test "marks a message undelivered when the server is busy or does not respond" do
      [Net::SMTPServerBusy.new("421 Try again later"), Net::ReadTimeout.new].each do |error|
        message = build_message

        deliver_raising(message, error)

        assert_equal "undelivered", message.state
        assert_nil message.provider_id
      end
    end

    private

    def deliver_raising(message, error)
      mailer = Object.new
      mailer.define_singleton_method(:deliver!) { |_mail| raise error }
      mailer.define_singleton_method(:settings) { {} }

      Mail::TestMailer.stub(:new, mailer) do
        Nuntius::SmtpMailProvider.new(message).deliver
      end
    end

    def build_message(to: "user@example.com", **attributes)
      Nuntius::Message.new(
        transport: "mail",
        provider: "smtp",
        to: to,
        subject: "Test",
        text: "Body",
        **attributes
      )
    end
  end
end
