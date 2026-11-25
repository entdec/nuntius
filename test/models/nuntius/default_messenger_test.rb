# frozen_string_literal: true

require "test_helper"

module Nuntius
  # A nuntiable class needs no messenger of its own, and a template's
  # attachments come from its text ({% attach %}), not from a messenger
  class DefaultMessengerTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      Current.account = @account
      @member = Member.create!(name: "Ann", email: "ann@example.com", account: @account)
    end

    test "a class without a messenger has the default one; one with its own, or its parent's, keeps it" do
      assert_equal DefaultMessenger, BaseMessenger.messenger_for_class("Member")
      assert_equal DefaultMessenger, BaseMessenger.messenger_for_obj(@member)
      assert_equal DefaultMessenger, BaseMessenger.messenger_for_class("NotAModel")
      assert_equal UserMessenger, BaseMessenger.messenger_for_class("User")
      assert_equal StiBaseMessenger, BaseMessenger.messenger_for_class("StiChild")
      assert Member.nuntiable?
    end

    test "its records are sent templates, with what their drops make attached" do
      template = Template.create!(klass: "Member", based_on: "on_demand", transport: "mail", description: "card", to: "{{ member }}", from: "from@example.com",
        subject: "Hi {{ to.name }}", text: "Your card{% attach member.card %}{% attach member.cards %}{% attach member.nothing %}", enabled: true, account: @account)

      message = template.deliver_to(@member).sole

      assert_equal ["ann@example.com", "Hi Ann"], [message.to, message.subject]
      assert_equal %w[back.txt card.txt card.txt], message.attachments.map { |attachment| attachment.filename.to_s }.sort
      assert_equal "Card of Ann", message.attachments.find { |attachment| attachment.filename.to_s == "card.txt" }.download
    end

    test "attach fetches a URL over http(s) only, never a file of the server" do
      template = Template.create!(klass: "Member", based_on: "on_demand", transport: "mail", description: "file", to: "{{ member }}", from: "from@example.com",
        subject: "Hi", text: "{% attach 'file:///etc/hosts' %}{% attach 'FILE:///etc/passwd' %}", enabled: true, account: @account)

      assert_empty template.deliver_to(@member).sole.attachments
    end
  end
end
