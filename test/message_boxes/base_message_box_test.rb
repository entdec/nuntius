# frozen_string_literal: true

require "test_helper"

class Nuntius::BaseMessageBoxTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "finds its descendants" do
    assert_equal [BarMessageBox, FooMessageBox, QuxMessageBox], Nuntius::BaseMessageBox.send(:descendants)
  end

  test "finds a message box for transport and provider" do
    assert_equal [FooMessageBox], Nuntius::BaseMessageBox.send(:message_box_for, transport: :sms)
    assert_equal [FooMessageBox], Nuntius::BaseMessageBox.send(:message_box_for, transport: :sms, provider: :twilio)
    assert_equal [BarMessageBox, QuxMessageBox], Nuntius::BaseMessageBox.send(:message_box_for, transport: :mail)
  end

  test "finds a message box matching a recipient" do
    assert_equal [FooMessageBox, :dutchies], Nuntius::BaseMessageBox.send(:message_box_for_route, [BarMessageBox, FooMessageBox], Nuntius::InboundMessage.new(to: %w[+31612345678]))
  end

  test "returns nil for no message box matching a recipient" do
    assert_nil Nuntius::BaseMessageBox.send(:message_box_for_route, [BarMessageBox, FooMessageBox], Nuntius::InboundMessage.new(to: %w[+33612345678]))
  end

  test "retrieves inbound mail" do
    # QuxMessageBox - mail / imap
    perform_enqueued_jobs do
      Nuntius::RetrieveMailJob.perform_now
    end
    assert_equal "hatseflats", QuxMessageBox.hatseflats
  end
end
