# frozen_string_literal: true

require "test_helper"

module Nuntius
  # The template form's parts of the event and interval
  class TemplateFormTest < ActiveSupport::TestCase
    def template(**attributes)
      Template.new(klass: "User", description: "Test", transport: "sms", **attributes).tap(&:validate)
    end

    test "based on an event: the event, without an interval or recurrence" do
      t = template(based_on: "event", event: "activate", interval: "2 days", recurrence: "yearly")

      assert_equal ["activate", nil, nil], [t.event, t.interval, t.recurrence]
    end

    test "based on time: before or after a timestamp, with an interval and recurrence" do
      t = template(based_on: "time", timestamp: "born_on", direction: "before", interval_amount: "4", interval_unit: "weeks", recurrence: "yearly")
      assert_equal ["before_born_on", "4 weeks", "yearly"], [t.event, t.interval, t.recurrence]

      t = template(based_on: "time", timestamp: "activated_at", direction: "after", interval_amount: "2", interval_unit: "days", recurrence: "")
      assert_equal ["after_activated_at", "2 days"], [t.event, t.interval]
      assert_predicate t.recurrence, :blank?
    end

    test "based on time: a timebased_scope, without a recurrence" do
      t = Template.new(klass: "Account", description: "Test", transport: "sms", based_on: "time", timestamp: "after_created", direction: "before", interval_amount: "5", interval_unit: "days", recurrence: "yearly").tap(&:validate)

      assert_equal ["after_created", "5 days", nil], [t.event, t.interval, t.recurrence]
    end

    test "the parts of a saved template" do
      t = Template.new(klass: "User", event: "before_born_on", interval: "1 week", recurrence: "yearly")
      assert_equal ["time", "born_on", "before", "1", "weeks"], [t.based_on, t.timestamp, t.direction, t.interval_amount, t.interval_unit]

      t = Template.new(klass: "Account", event: "after_created", interval: "5 days")
      assert_equal ["time", "after_created"], [t.based_on, t.timestamp]

      t = Template.new(klass: "User", event: "activate")
      assert_equal "event", t.based_on
      assert_nil t.timestamp
    end

    test "without the form's parts, as before" do
      t = template(event: "before_born_on", interval: "4 weeks", recurrence: "yearly")

      assert_equal ["before_born_on", "4 weeks", "yearly"], [t.event, t.interval, t.recurrence]
    end
  end
end
