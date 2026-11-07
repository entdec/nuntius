# frozen_string_literal: true

require "test_helper"

module Nuntius
  class OwnedTest < ActiveSupport::TestCase
    setup do
      @other = Account.create!(name: "other")
    end

    test "a new record gets the current account" do
      assert_equal accounts(:one), Nuntius::List.create!(name: "News", slug: "news").account
    end

    test "a new record keeps the account it's given" do
      assert_equal @other, Nuntius::List.create!(name: "News", slug: "news", account: @other).account
    end

    test "a record needs an account" do
      Current.account = nil
      list = Nuntius::List.new(name: "News", slug: "news")

      assert_not list.valid?
      assert list.errors.added?(:account, :blank)
    end

    test "owned_by takes accounts or their ids" do
      other_list = Nuntius::List.create!(name: "Other", slug: "other", account: @other)

      assert_equal [other_list], Nuntius::List.owned_by(@other).to_a
      assert_equal [other_list], Nuntius::List.owned_by([@other.id]).to_a
      assert_not_includes Nuntius::List.owned_by(@other), nuntius_lists(:valentines)
    end

    test "a template is available to its own account, and a global one to every account" do
      own = Nuntius::Template.create!(description: "own", klass: "Account", event: "created", transport: "mail", account: @other)
      global = Nuntius::Template.create!(description: "global", klass: "Account", event: "created", transport: "mail", global: true)

      assert_includes Nuntius::Template.available_to(@other), own
      assert_includes Nuntius::Template.available_to(@other), global
      assert_not_includes Nuntius::Template.available_to(@other), nuntius_templates(:email)
      assert_not_includes Nuntius::Template.available_to(accounts(:one)), own
    end
  end
end
