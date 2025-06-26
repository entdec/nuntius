require "test_helper"
require "minitest/mock"

module Nuntius
  class TimeBasedEventsJobTest < ActiveJob::TestCase
    setup do
    end

    test "will only send out messages when due" do
      template1 = Nuntius::Template.create!(description: "template1", klass: "Account", transport: "mail", event: "after_created", to: "test@example.org", html: "Hello {{name}} - 5 days", interval: "5 days", created_at: 1.month.ago)
      template2 = Nuntius::Template.create!(description: "template2", klass: "Account", transport: "mail", event: "after_created", to: "test@example.org", html: "Hello {{name}} - 10 days", interval: "10 days", created_at: 1.month.ago)
      account = accounts(:one)
      account.update!(created_at: 5.days.ago)

      assert_difference -> { Nuntius::Message.count }, 1 do
        perform_enqueued_jobs only: [Nuntius::MessengerJob, Nuntius::TimebasedEventsJob] do
          Nuntius::TimebasedEventsJob.perform_now
        end
      end

      subject = Nuntius::Message.where(template: template1).first
      subject2 = Nuntius::Message.where(template: template2).first
      assert subject
      assert_nil subject2
      assert_equal 1, Nuntius::Message.where(template: [template1, template2]).count
      assert_includes subject.html, "- 5 days"
    end
  end
end
