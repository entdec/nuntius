# frozen_string_literal: true

require "test_helper"

module Nuntius
  # The account a messenger sends for, and the templates it picks for it
  class MessengerAccountTest < ActiveSupport::TestCase
    setup do
      @customer = Account.create!(name: "customer")
      @other = Account.create!(name: "other")
      @root = Account.create!(name: "root")
    end

    test "an account sends for itself" do
      assert_equal @customer, AccountMessenger.new(@customer, :created).account
    end

    test "an object sends for its account" do
      user = User.create!(name: "user", account: @customer)

      assert_equal @customer, UserMessenger.new(user, :created).account
    end

    test "an object without an account sends for the current account" do
      assert_equal accounts(:one), Nuntius::CustomMessenger.new({order: {}}, :placed).account
    end

    test "a messenger can say which account it sends for, and its subclasses inherit that" do
      messenger = Class.new(Nuntius::CustomMessenger) { account ->(object) { Account.find_by!(name: object[:order][:account]) } }

      assert_equal @other, messenger.new({order: {account: "other"}}, :placed).account
      assert_equal @other, Class.new(messenger).new({order: {account: "other"}}, :placed).account
    end

    test "sending without an account raises" do
      template(@customer, klass: "Custom", event: "order#placed")
      Current.account = nil

      assert_raises(Nuntius::MissingAccountException) { Nuntius::CustomMessenger.new({order: {}}, :placed).templates.to_a }
    end

    test "without templates no account is needed" do
      Current.account = nil

      assert_empty Nuntius::CustomMessenger.new({order: {}}, :placed).templates
    end

    test "picks the account's own templates and the global ones, not another account's" do
      own = template(@customer)
      global = template(@root, global: true, transport: "sms")
      template(@other)
      template(@root)

      assert_equal [own, global].sort_by(&:id), AccountMessenger.new(@customer, :created).templates.sort_by(&:id)
    end

    test "a global template is left out for a transport the account has its own template for" do
      own = template(@customer)
      template(@root, global: true)
      global_sms = template(@root, global: true, transport: "sms")

      assert_equal [own, global_sms].sort_by(&:id), AccountMessenger.new(@customer, :created).templates.sort_by(&:id)
      assert_equal 2, AccountMessenger.new(@other, :created).templates.count
    end

    test "template_scope narrows the templates further" do
      template(@customer)
      global = template(@root, global: true, transport: "sms")
      messenger = Class.new(AccountMessenger) { template_scope ->(_account) { where(transport: "sms") } }

      assert_equal [global], messenger.new(@customer, :created).templates.to_a
    end

    test "a message belongs to the account it's sent for, also with a global template" do
      global = template(@root, global: true)

      AccountMessenger.new(@customer, :created).dispatch([global])

      assert_equal @customer, Nuntius::Message.find_by!(template: global).account
    end

    private

    def template(account, global: false, transport: "mail", klass: "Account", event: "created")
      Nuntius::Template.create!(account: account, global: global, klass: klass, event: event, transport: transport, description: "#{account.name} #{transport}", to: "user@example.com", text: "Hi")
    end
  end
end
