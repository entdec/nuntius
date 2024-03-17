# frozen_string_literal: true

require "test_helper"

module Nuntius
  class TemplateTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    setup do
      Mail::TestMailer.deliveries.clear
    end

    test "translation scope" do
      t = Template.new(transport: "slack", klass: "Cow", event: "moo")
      assert_equal "cow.moo.slack", t.translation_scope
    end

    test "interval_duration is zero seconds when it is not given" do
      t = Template.new
      assert_equal 0.seconds, t.interval_duration
    end

    test "interval_duration is calculated based on input" do
      t = Template.new(interval: "3 seconds")
      assert_equal 3.seconds, t.interval_duration

      t = Template.new(interval: "5 minutes")
      assert_equal 5.minutes, t.interval_duration

      t = Template.new(interval: "7 days")
      assert_equal 7.days, t.interval_duration
    end

    test "interval_time_range gives an empty range when there is no interval" do
      t = Template.new
      assert_equal 0.seconds..0.seconds, t.interval_time_range
    end

    test "interval_time_range for after events" do
      t = Template.new(interval: "3 hours", event: "after_the_fact")
      assert_equal timerange(4.hours.ago..3.hours.ago), timerange(t.interval_time_range)
    end

    test "interval_time_range for before events" do
      t = Template.new(interval: "2 hours", event: "before_the_fact")
      assert_equal timerange(1.hours.after..2.hour.after), timerange(t.interval_time_range)
    end

    test "delivering a mail to multiple recipients with translations should work" do
      perform_enqueued_jobs(only: [Nuntius::TransportDeliveryJob, Nuntius::MessengerJob]) do
        Nuntius.event(:translationtest, accounts(:one), locale: "nl")
      end
      assert_performed_jobs 3

      assert_equal 2, Mail::TestMailer.deliveries.length
      mail = Mail::TestMailer.deliveries.first
      assert_equal "Smurrefluts", mail.subject
      mail = Mail::TestMailer.deliveries.last
      assert_equal "Smurrefluts", mail.subject
      Mail::TestMailer.deliveries.clear
    end

    test "template with attachment from url" do
      VCR.use_cassette("boxture_logo_with_content_disposition", match_requests_on: [:body]) do
        t = Template.new(transport: "mail", html: %(Hello {%attach 'https://www.boxture.com/assets/images/logo.png'%}))
        m = t.new_message({})
        assert_equal "<p>Hello</p>\n", m.html
        assert_equal 1, m.attachments.size

        attachment = m.attachments.first

        assert_equal "boxture_logo.png", attachment.content.filename.to_s
        assert_equal "image/png", attachment.content.content_type
      end
    end

    test "template with attachment from has one attachment" do
      account = Account.create!(name: "Test")

      account.logo.attach(io: File.open(Rails.root.join("..", "..", "test", "fixtures", "files", "logo_blue@3x.png")), filename: "logo_blue@3x.png", content_type: "image/png")

      t = Template.new(transport: "mail", html: %(Hello {%attach account.logo%}))
      m = t.new_message({}, {"account" => account})
      assert_equal "<p>Hello</p>\n", m.html
      assert_equal 1, m.attachments.size

      attachment = m.attachments.first

      assert_equal "logo_blue@3x.png", attachment.content.filename.to_s
      assert_equal "image/png", attachment.content.content_type
    end

    test "template with attachment from has many attachment" do
      account = Account.create!(name: "Test")

      account.attachments.attach(io: File.open(Rails.root.join("..", "..", "test", "fixtures", "files", "logo_blue@3x.png")), filename: "logo_blue@3x.png", content_type: "image/png")

      t = Template.new(transport: "mail", html: %(Hello {%assign atts = account.attachments | where: 'filename', 'logo_blue@3x.png'%}{%attach atts.first%}))
      m = t.new_message({}, {"account" => account})
      assert_equal "<p>Hello</p>\n", m.html
      assert_equal 1, m.attachments.size

      attachment = m.attachments.first

      assert_equal "logo_blue@3x.png", attachment.content.filename.to_s
      assert_equal "image/png", attachment.content.content_type
    end

    private

    def timerange(range)
      [range.begin.iso8601, range.end.iso8601]
    end
  end
end
