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

  test "a message box's mailboxes: its own, and those its block gives each time" do
    klass = Class.new(Nuntius::BaseMessageBox) do
      transport :mail
      provider :imap
      mailbox :orders, {address: "imap.example.com"}
    end
    inboxes = [["returns", {address: "imap.example.org"}]]
    called = false
    klass.mailboxes { inboxes.tap { called = true } }
    refute called, "not when it's given: the app's data may not be there yet when the class is loaded"

    assert_equal({"orders" => {address: "imap.example.com"}, "returns" => {address: "imap.example.org"}}, klass.mailboxes)
    inboxes << [42, {}]
    assert_equal %w[orders returns 42], klass.mailboxes.keys
  end

  test "a mailbox that can't be fetched is reported, the others are fetched, and their message boxes hear how it went" do
    fetches = []
    QuxMessageBox.fetched { |mailbox, error| fetches << [mailbox, error&.message] }
    failing = ->(settings:, message_box:, mailbox:) { raise SocketError, "Invalid credentials" if message_box == "BarMessageBox" }

    Nuntius::RetrieveInboundMailService.stub(:perform, failing) do
      assert_error_reported(SocketError) { Nuntius::RetrieveMailJob.perform_now }
    end
    assert_equal [["default", nil]], fetches

    BarMessageBox.fetched { |mailbox, error| fetches << [mailbox, error&.message] }
    Nuntius::RetrieveInboundMailService.stub(:perform, failing) do
      Nuntius::RetrieveMailJob.perform_now
    end
    assert_includes fetches, ["default", "Invalid credentials"]
  ensure
    [QuxMessageBox, BarMessageBox].each { |klass| klass.instance_variable_set(:@fetched_block, nil) }
  end

  test "settings is its default mailbox's, deprecated" do
    klass = Class.new(Nuntius::BaseMessageBox)

    assert_output(nil, /settings is deprecated/) { klass.settings({address: "imap.example.com"}) }
    assert_equal({"default" => {address: "imap.example.com"}}, klass.mailboxes)
    assert_equal({address: "imap.example.com"}, klass.settings)
  end

  test "fetched mail is recorded with its message box and mailbox, and goes to that message box" do
    Nuntius::RetrieveInboundMailService.perform(settings: {}, message_box: "BarMessageBox", mailbox: "default")
    message = Nuntius::InboundMessage.order(:created_at).last
    assert_equal ["BarMessageBox", "default"], [message.message_box, message.mailbox]

    # BarMessageBox has no route for it, so QuxMessageBox's catch-all doesn't get it either
    QuxMessageBox.instance_variable_set(:@hatseflats, nil)
    assert_nil Nuntius::BaseMessageBox.deliver(message)
    assert_nil QuxMessageBox.hatseflats

    message.update!(message_box: "QuxMessageBox")
    assert Nuntius::BaseMessageBox.deliver(message)
    assert_equal "hatseflats", QuxMessageBox.hatseflats
  end

  test "the same mail in two mailboxes is two messages, fetched once each" do
    assert_difference "Nuntius::InboundMessage.count", 40 do
      Nuntius::RetrieveInboundMailService.perform(settings: {}, message_box: "QuxMessageBox", mailbox: "orders")
      Nuntius::RetrieveInboundMailService.perform(settings: {}, message_box: "QuxMessageBox", mailbox: "returns")
      Nuntius::RetrieveInboundMailService.perform(settings: {}, message_box: "QuxMessageBox", mailbox: "returns")
    end
  end

  test "a message box's mailbox is the one its message was fetched from" do
    message = Nuntius::InboundMessage.new(transport: "mail", provider: "imap", mailbox: "returns")

    assert_equal "returns", QuxMessageBox.new(message).mailbox
  end
end
