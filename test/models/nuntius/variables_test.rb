# frozen_string_literal: true

require "test_helper"

module Nuntius
  class VariablesTest < ActiveSupport::TestCase
    test "a model's drop under its messenger's name for it" do
      assert_equal({"account" => AccountDrop}, Variables.for_class("Account"))
    end

    test "nothing for Custom, an unknown class, or a class without a drop" do
      assert_equal({}, Variables.for_class("Custom"))
      assert_equal({}, Variables.for_class("Cow"))
      assert_equal({}, Variables.for_class("Report"))
      assert_equal({}, Variables.for_class(nil))
    end

    test "a template has the object it's sent for and itself" do
      assert_equal({"account" => AccountDrop, "template" => TemplateDrop}, Template.new(klass: "Account").variable_roots)
      assert_equal({"template" => TemplateDrop}, Template.new(klass: "Custom").variable_roots)
    end

    test "a campaign has itself, the subscriber and what its list's subscribers are" do
      list = nuntius_lists(:valentines)
      list.subscribers.create!(first_name: "Juliet", nuntiable: ::User.create!(name: "Juliet", account: accounts(:one)))
      roots = Campaign.new(list: list).variable_roots

      assert_equal({"user" => UserDrop, "campaign" => CampaignDrop, "subscriber" => SubscriberDrop, "subscriber_url" => :string}, roots)
    end

    test "a layout has the template or campaign it's part of" do
      assert_equal({"template" => TemplateDrop, "campaign" => CampaignDrop}, Layout.new.variable_roots)
    end

    test "the editor's URL only when the host app mounts Liquidum" do
      assert_nil Variables.url(Object.new, {"template" => TemplateDrop})
    end

    test "Nuntius's drops describe their variables, through to other Nuntius objects" do
      subscriber = SubscriberDrop.variables.index_by(&:name)
      assert_equal ListDrop, subscriber["list"].drop
      assert_equal "First name", subscriber["first_name"].label
      assert_includes ListDrop.variables.map(&:name), "allow_unsubscribe"
      assert_equal LayoutDrop, TemplateDrop.variables.find { |variable| variable.name == "layout" }.drop
    end
  end
end
