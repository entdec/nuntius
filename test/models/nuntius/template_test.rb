# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class TemplateTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

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
      assert_equal (4.hours.ago..3.hours.ago).inspect, t.interval_time_range.inspect
    end

    test 'interval_time_range for before events' do
      t = Template.new(interval: '2 hours', event: 'before_the_fact')
      assert_equal (1.hours.after..2.hour.after).inspect, t.interval_time_range.inspect
    end

    test 'delivering a mail to multiple recipients with translations should work' do
      perform_enqueued_jobs(only: [Nuntius::TransportDeliveryJob, Nuntius::MessengerJob]) do
        Nuntius.with(accounts(:one), locale: 'nl').message(:translationtest)
      end
      assert_performed_jobs 3

      assert_equal 2, Mail::TestMailer.deliveries.length
      mail = Mail::TestMailer.deliveries.first
      assert_equal 'Smurrefluts', mail.subject
      mail = Mail::TestMailer.deliveries.last
      assert_equal 'Smurrefluts', mail.subject
      Mail::TestMailer.deliveries.clear
    end
  end
end
