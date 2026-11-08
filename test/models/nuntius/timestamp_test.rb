# frozen_string_literal: true

require "test_helper"

module Nuntius
  # Templates sent around a model's dates and times
  class TimestampTest < ActiveSupport::TestCase
    def due(event, interval, recurrence = nil)
      template = Template.new(klass: "User", event: event, interval: interval, recurrence: recurrence)
      UserMessenger.timestamp_for(event, "User").due(template)
    end

    test "a model's date and time columns, and the _at keys of its stores" do
      names = Timestamp.for(User).map(&:name)

      assert_includes names, "born_on"
      assert_includes names, "created_at"
      assert_includes names, "activated_at"
      assert_not_includes names, "welcomed"
      assert_equal [], Timestamp.for(nil)
    end

    test "before and after each timestamp are events, except updated_at and hidden ones" do
      events = UserMessenger.events("User")

      assert_includes events, :before_born_on
      assert_includes events, :after_activated_at
      assert_includes events, :activate
      assert_not_includes events, :after_updated_at
      assert_equal :before, UserMessenger.timebased(:before_born_on, "User")
      assert_equal :after, AccountMessenger.timebased(:after_created_at, "Account")
      assert_nil UserMessenger.timebased(:activate, "User")

      messenger = Class.new(UserMessenger) { hide_timestamps :born_on }
      assert_not_includes messenger.events("User"), :before_born_on
      assert_includes messenger.events("User"), :after_activated_at
    end

    test "a timebased_scope is ignored, with a warning" do
      messenger = nil
      _, warning = capture_io do
        messenger = Class.new(AccountMessenger) do
          timebased_scope(:after_created_at) { |_time_range, _template| Account.none }
        end
      end

      assert_match(/timebased_scope :after_created_at is ignored/, warning)
      assert_equal "created_at", messenger.timestamp_for(:after_created_at, "Account").name
      assert_not_includes messenger.instance_methods, :after_created_at
    end

    test "their events read as the timestamp is in, or was" do
      assert_equal "Born on is in", UserMessenger.event_label(:before_born_on, "User")
      assert_equal "Activated at was", UserMessenger.event_label(:after_activated_at, "User")

      messenger = Class.new(UserMessenger) { describe :born_on, label: -> { "birthday" } }
      assert_equal "birthday is in", messenger.event_label(:before_born_on, "User")
    end

    test "a time is due in the hour up to its interval" do
      user = User.create!(name: "Juliet", activated_at: 2.weeks.ago - 10.minutes)
      User.create!(name: "Romeo", activated_at: 2.weeks.ago - 2.hours)

      assert_equal [user], due("after_activated_at", "2 weeks").to_a
    end

    test "a date is due on its day, from the send hour" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        user = User.create!(name: "Juliet", born_on: Date.new(2027, 4, 7))

        assert_equal [user], due("before_born_on", "4 weeks").to_a
        assert_empty due("before_born_on", "3 weeks")
      end
      travel_to Time.zone.local(2027, 3, 10, 8) do
        assert_empty due("before_born_on", "4 weeks")
      end
    end

    test "every year: a birthday" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        birthday = User.create!(name: "Juliet", born_on: Date.new(1990, 4, 7))
        User.create!(name: "Romeo", born_on: Date.new(1990, 4, 8))
        User.create!(name: "Unborn", born_on: Date.new(2030, 4, 7))

        today = User.create!(name: "Today", born_on: Date.new(1985, 3, 10))

        assert_equal [birthday], due("before_born_on", "4 weeks", "yearly").to_a
        assert_equal [today], due("after_born_on", "0 days", "yearly").to_a
      end
    end

    test "every month, quarter and half year: the same day of the month, or its last day" do
      travel_to Time.zone.local(2027, 2, 28, 10) do
        end_of_january = User.create!(name: "January", born_on: Date.new(2026, 1, 31))
        november = User.create!(name: "November", born_on: Date.new(2026, 11, 28))
        august = User.create!(name: "August", born_on: Date.new(2026, 8, 28))
        User.create!(name: "Other", born_on: Date.new(2026, 12, 27))

        assert_equal [end_of_january, november, august].sort_by(&:name), due("after_born_on", "0 days", "monthly").sort_by(&:name)
        assert_equal [november, august].sort_by(&:name), due("after_born_on", "0 days", "quarterly").sort_by(&:name)
        assert_equal [august], due("after_born_on", "0 days", "half_yearly").to_a
      end
    end

    test "every week and every day" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        two_weeks = User.create!(name: "Two weeks", born_on: Date.new(2027, 2, 24))
        ten_days = User.create!(name: "Ten days", born_on: Date.new(2027, 2, 28))

        assert_equal [two_weeks], due("after_born_on", "0 days", "weekly").to_a
        assert_equal [ten_days, two_weeks].sort_by(&:name), due("after_born_on", "0 days", "daily").sort_by(&:name)
      end
    end

    test "only the recurrences there are" do
      assert Template.new(recurrence: "yearly").tap(&:validate).errors[:recurrence].empty?
      assert_not Template.new(recurrence: "hourly").tap(&:validate).errors[:recurrence].empty?
    end
  end
end
