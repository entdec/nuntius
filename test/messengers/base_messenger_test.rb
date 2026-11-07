# frozen_string_literal: true

require "test_helper"

module Nuntius
  class BaseMessengerTest < ActiveSupport::TestCase
    test "persists headers and a null envelope sender onto the message" do
      template = create_template
      messenger = AccountMessenger.new(accounts(:one), :created, {})

      messenger.header("Auto-Submitted", "auto-replied")
      messenger.header("Precedence", "bulk")
      messenger.smtp_envelope_from = "<>"
      messenger.dispatch([template])

      message = Nuntius::Message.where(template: template).last
      assert_equal "auto-replied", message.headers["Auto-Submitted"]
      assert_equal "bulk", message.headers["Precedence"]
      assert_equal "<>", message.envelope_from
    end

    test "headers/envelope can be supplied through params" do
      template = create_template
      messenger = AccountMessenger.new(
        accounts(:one), :created,
        {headers: {"Auto-Submitted" => "auto-replied"}, smtp_envelope_from: "<>"}
      )

      messenger.dispatch([template])

      message = Nuntius::Message.where(template: template).last
      assert_equal "auto-replied", message.headers["Auto-Submitted"]
      assert_equal "<>", message.envelope_from
    end

    test "sets no headers or envelope sender when none are set" do
      template = create_template
      AccountMessenger.new(accounts(:one), :created, {}).dispatch([template])

      message = Nuntius::Message.where(template: template).last
      assert_equal({}, message.headers)
      assert_nil message.envelope_from
    end

    private

    def create_template
      Nuntius::Template.create!(
        klass: "Account",
        event: "created",
        transport: "mail",
        description: "created",
        to: "user@example.com",
        from: "from@example.com",
        subject: "Hi",
        text: "Body",
        enabled: true
      )
    end
  end
end
