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

    test "without rules they're met" do
      assert Conditions.new.met?({})
      assert Conditions.new(nil).empty?
    end

    test "is and isn't: a drop's text, ignoring case" do
      assert met?(rule("user.state", "is", "Active"), "user" => @user)
      assert_not met?(rule("user.state", "isnt", "active"), "user" => @user)
      assert met?(rule("user.name", "isnt", "Romeo"), "user" => @user)
    end

    test "a question: is true, or false" do
      assert met?(rule("user.active?", "is", "true"), "user" => @user)
      assert_not met?(rule("user.active?", "is", "false"), "user" => @user)
      @user.state = "disabled"
      assert met?(rule("user.active?", "isnt", "true"), "user" => @user)
    end

    test "contains and doesn't contain" do
      assert met?(rule("user.name", "matches", "capulet"), "user" => @user)
      assert met?(rule("user.email", "does_not_match", "montague"), "user" => @user)
      assert_not met?(rule("user.email", "matches", "montague"), "user" => @user)
    end

    test "empty and not empty: nil, blank text, a missing variable" do
      assert met?(rule("user.email", "isnt_empty"), "user" => @user)
      @user.email = ""
      assert met?(rule("user.email", "is_empty"), "user" => @user)
      assert met?(rule("user.nothing", "is_empty"), "user" => @user)
      assert met?(rule("order.number", "is_empty"), {})
    end

    test "numbers and dates compare as numbers and dates" do
      order = {"total" => 120.5, "placed_on" => Date.new(2027, 3, 10)}

      assert met?(rule("order.total", "gt", "100"), "order" => order)
      assert met?(rule("order.total", "lteq", "120.5"), "order" => order)
      assert_not met?(rule("order.total", "lt", "20"), "order" => order)
      assert met?(rule("order.total", "between", "100", "200"), "order" => order)
      assert_not met?(rule("order.total", "between", "1", "2"), "order" => order)
      assert met?(rule("order.total", "is", "120.50"), "order" => order)
      assert met?(rule("user.born_on", "lt", "2000-01-01"), "user" => @user)
      assert met?(rule("order.placed_on", "gteq", "2027-03-10"), "order" => order)
      assert_not met?(rule("order.total", "gt", "lots"), "order" => order)
    end

    test "a list is one of its elements" do
      assert met?(rule("order.tags", "is", "gift"), "order" => {"tags" => %w[gift express]})
      assert met?(rule("order.tags", "matches", "press"), "order" => {"tags" => %w[gift express]})
      assert met?(rule("order.tags", "is_empty"), "order" => {"tags" => []})
    end

    test "all, or any, of them" do
      rules = [rule("user.state", "is", "active"), rule("user.name", "is", "Romeo")]

      assert_not met?(rules, {"user" => @user})
      assert met?(rules, {"user" => @user}, "any")
    end

    test "from the form: numbered rules, and leaving out those without a variable or operator" do
      conditions = Conditions.new("match" => "any", "rules" => {"0" => rule("user.state", "is", "active"), "1" => rule("", "is", "x"), "2" => rule("user.name", "sounds_like", "x")})

      assert_equal({"match" => "any", "rules" => [{"variable" => "user.state", "operator" => "is", "value" => "active", "value_to" => ""}]}, conditions.to_h)
      assert_equal "all", Conditions.new("match" => "some").match
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
