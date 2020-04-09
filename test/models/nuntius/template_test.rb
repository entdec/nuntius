# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class TemplateTest < ActiveSupport::TestCase
    test 'translation scope' do
      t = Template.new(transport: 'slack', klass: 'Cow', event: 'moo')
      assert_equal 'cow.moo.slack', t.translation_scope
    end

    test 'interval_duration is zero seconds when it is not given' do
      t = Template.new
      assert_equal 0.seconds, t.interval_duration
    end

    test 'interval_duration is calculated based on input' do
      t = Template.new(interval: '3 seconds')
      assert_equal 3.seconds, t.interval_duration

      t = Template.new(interval: '5 minutes')
      assert_equal 5.minutes, t.interval_duration

      t = Template.new(interval: '7 days')
      assert_equal 7.days, t.interval_duration
    end

    test 'interval_time_range gives an empty range when there is no interval' do
      t = Template.new
      assert_equal 0.seconds..0.seconds, t.interval_time_range
    end

    test 'interval_time_range for after events' do
      t = Template.new(interval: '3 hours', event: 'after_the_fact')
      assert_equal (3.hours.ago..2.hours.ago).inspect, t.interval_time_range.inspect
    end

    test 'interval_time_range for before events' do
      t = Template.new(interval: '2 hours', event: 'before_the_fact')
      assert_equal (2.hours.after..3.hour.after).inspect, t.interval_time_range.inspect
    end
  end
end
