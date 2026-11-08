# frozen_string_literal: true

require "test_helper"

module Nuntius
  # The template form's parts of the event and interval
  class TemplateFormTest < ActiveSupport::TestCase
    def template(**attributes)
      Template.new(klass: "User", description: "Test", transport: "sms", **attributes).tap(&:validate)
    end

    test "its limit: its own, or the configured one" do
      assert_equal Nuntius.config.timebased_limit, template.send_limit
      assert_equal 20, template(timebased_limit: 20).send_limit
      assert_includes template(timebased_limit: 0).errors.attribute_names, :timebased_limit
    end

    test "how many it would send to now: a date today, also before the send hour; at most one more than its limit" do
      travel_to Time.zone.local(2027, 3, 10, 7) do
        3.times { |i| User.create!(name: "User #{i}", email: "user#{i}@example.org", born_on: Date.new(1990, 3, 10), account: accounts(:one)) }
        birthday = Template.create!(klass: "User", description: "Birthday", transport: "sms", event: "before_born_on", interval: "0 days", recurrence: "yearly", global: true, account: accounts(:one))

        assert_equal 3, birthday.due_count
        assert birthday.due_today?
        birthday.timebased_limit = 1
        assert_equal 2, birthday.due_count

        activated = Template.new(klass: "User", event: "after_activated_at", interval: "2 hours")
        assert_not activated.due_today?
        assert_nil Template.new(klass: "User", event: "activate").due_count
      end
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

    test "the parts of a saved template" do
      t = Template.new(klass: "User", event: "before_born_on", interval: "1 week", recurrence: "yearly")
      assert_equal ["time", "born_on", "before", "1", "weeks"], [t.based_on, t.timestamp, t.direction, t.interval_amount, t.interval_unit]

      t = Template.new(klass: "Account", event: "after_created_at", interval: "5 days")
      assert_equal ["time", "created_at", "after"], [t.based_on, t.timestamp, t.direction]

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
