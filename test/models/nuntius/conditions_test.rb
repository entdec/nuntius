# frozen_string_literal: true

require "test_helper"

module Nuntius
  # Whether a message is sent, by its Liquid variables
  class ConditionsTest < ActiveSupport::TestCase
    def met?(rules, assigns = {}, match = "all")
      Conditions.new("match" => match, "rules" => Array.wrap(rules)).met?(assigns)
    end

    def rule(variable, operator, value = nil, value_to = nil)
      {"variable" => variable, "operator" => operator, "value" => value, "value_to" => value_to}
    end

    setup do
      @user = User.new(name: "Juliet Capulet", email: "juliet@example.com", state: "active", born_on: Date.new(1990, 4, 7))
    end

    test "they're Liquidum's, which has the cases of what's met (Liquidum::Conditions)" do
      assert_same Liquidum::Conditions, Conditions
    end

    test "a drop's variables and questions" do
      assert met?([rule("user.state", "is", "Active"), rule("user.active?", "is", "true")], "user" => @user)
      @user.state = "disabled"
      assert met?(rule("user.active?", "isnt", "true"), "user" => @user)
      assert met?(rule("user.born_on", "lt", "2000-01-01"), "user" => @user)
    end

    test "templates keep them, and send only when they're met" do
      template = Template.create!(klass: "Account", event: "created", transport: "mail", description: "created", to: "user@example.com", from: "from@example.com", subject: "Hi", text: "Body", enabled: true,
        conditions: {"match" => "all", "rules" => {"0" => rule("account.name", "is", "Nobody")}})
      assert_equal "account.name", template.reload.conditions["rules"].first["variable"]

      AccountMessenger.new(accounts(:one), :created, {}).dispatch([template])
      assert_empty Message.where(template: template)

      template.update!(conditions: {"rules" => [rule("account.name", "is", accounts(:one).name)]})
      AccountMessenger.new(accounts(:one), :created, {}).dispatch([template])
      assert_equal 1, Message.where(template: template).count
    end

    test "a template's conditions can use the template" do
      template = Template.new(layout: Layout.new(name: "Plain"), conditions: {"rules" => [rule("template.layout.name", "is", "plain")]})

      assert template.conditions_met?("template" => template)
      assert_not template.conditions_met?({})
    end
  end
end
