# frozen_string_literal: true

require "test_helper"

# The names templates show for the events they're sent on
class EventLabelsTest < ActiveSupport::TestCase
  teardown do
    I18n.reload!
  end

  test "an event is its name without anything to name it by" do
    assert_equal "after created", AccountMessenger.event_label(:after_created)
    assert_equal "activate", UserMessenger.event_label(:activate)
  end

  test "the model's state machine names its events" do
    I18n.backend.store_translations(:nl, activerecord: {state_machines: {user: {events: {activate: "geactiveerd is"}}}})

    assert_equal "geactiveerd is", I18n.with_locale(:nl) { UserMessenger.event_label(:activate) }
  end

  test "Nuntius's translations name any event" do
    I18n.backend.store_translations(:nl, nuntius: {events: {account: {after_created: "aangemaakt is"}, user: {activate: "actief wordt"}}})

    I18n.with_locale(:nl) do
      assert_equal "aangemaakt is", AccountMessenger.event_label(:after_created)
      assert_equal "actief wordt", UserMessenger.event_label(:activate)
    end
  end

  test "a messenger describes its events" do
    messenger = Class.new(Nuntius::BaseMessenger) do
      describe :shipped, label: -> { "is shipped" }
      describe :paid, label: "is paid"
    end

    assert_equal "is shipped", messenger.event_label(:shipped, "Account")
    assert_equal "is paid", messenger.event_label("paid", "Account")
  end

  test "a template's class and event, for people" do
    I18n.backend.store_translations(:en, nuntius: {events: {user: {activate: "is activated"}}})

    assert_equal "User", Nuntius::Template.new(klass: "User").klass_label
    assert_equal "is activated", Nuntius::Template.new(klass: "User", event: "activate").event_label
    assert_equal "Custom event", Nuntius::Template.new(klass: "Custom").klass_label
    assert_equal "order#shipped", Nuntius::Template.new(klass: "Custom", event: "order#shipped").event_label
  end
end
