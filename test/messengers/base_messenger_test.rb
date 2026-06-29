# frozen_string_literal: true

require "test_helper"

module Nuntius
  class BaseMessengerTest < ActiveSupport::TestCase
    test "persists headers and a null envelope sender onto the message metadata" do
      template = create_template
      messenger = AccountMessenger.new(accounts(:one), :created, {})

      messenger.header("Auto-Submitted", "auto-replied")
      messenger.header("Precedence", "bulk")
      messenger.smtp_envelope_from = "<>"
      messenger.dispatch([template])

      message = Nuntius::Message.where(template: template).last
      assert_equal "auto-replied", message.metadata.dig("mail", "headers", "Auto-Submitted")
      assert_equal "bulk", message.metadata.dig("mail", "headers", "Precedence")
      assert_equal "<>", message.metadata.dig("mail", "envelope_from")
    end

    test "headers/envelope can be supplied through params" do
      template = create_template
      messenger = AccountMessenger.new(
        accounts(:one), :created,
        {headers: {"Auto-Submitted" => "auto-replied"}, smtp_envelope_from: "<>"}
      )

      messenger.dispatch([template])

      message = Nuntius::Message.where(template: template).last
      assert_equal "auto-replied", message.metadata.dig("mail", "headers", "Auto-Submitted")
      assert_equal "<>", message.metadata.dig("mail", "envelope_from")
    end

    test "leaves metadata untouched when no overrides are set" do
      template = create_template
      AccountMessenger.new(accounts(:one), :created, {}).dispatch([template])

      message = Nuntius::Message.where(template: template).last
      assert_nil message.metadata["mail"]
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
        enabled: true,
        metadata: {}
      )
    end
  end
end
