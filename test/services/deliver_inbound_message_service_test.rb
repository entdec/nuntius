# frozen_string_literal: true

require "test_helper"

module Nuntius
  class DeliverInboundMessageServiceTest < ActiveSupport::TestCase
    test "retrieves new mail" do
      inbound_message = Nuntius::InboundMessage.create!(transport: "mail", provider: "imap", provider_id: "1", digest: "1", status: "pending")
      inbound_message.from = "some@example.com"
      inbound_message.to = "support@example.com"
      inbound_message.text = "Help!"
      inbound_message.save!

      Nuntius::DeliverInboundMessageService.perform(inbound_message: inbound_message)

      inbound_message.reload

      assert_equal "delivered", inbound_message.status
      assert_equal "hatseflats", QuxMessageBox.hatseflats
    end
  end
end
