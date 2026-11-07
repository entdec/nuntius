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

    test "sends a timebased template only for its own account, and a global one for accounts without their own" do
      account = Account.create!(name: "target", created_at: 5.days.ago)
      other_account = Account.create!(name: "other", created_at: 5.days.ago)
      root = Account.create!(name: "root", created_at: 1.year.ago)
      plain_account = Account.create!(name: "plain", created_at: 5.days.ago)

      template = ->(description, owner, global = false) { Nuntius::Template.create!(description: description, klass: "Account", transport: "mail", event: "after_created", to: "test@example.org", html: "Hello {{name}} - #{description}", interval: "5 days", created_at: 1.month.ago, account: owner, global: global) }
      account_template = template.call("account", account)
      other_account_template = template.call("other", other_account)
      global_template = template.call("global", root, true)

      perform_enqueued_jobs only: [Nuntius::MessengerJob, Nuntius::TimebasedEventsJob] do
        Nuntius::TimebasedEventsJob.perform_now
      end

      assert_equal [account_template.id], Nuntius::Message.where(nuntiable: account).pluck(:template_id)
      assert_equal [other_account_template.id], Nuntius::Message.where(nuntiable: other_account).pluck(:template_id)
      assert_equal [global_template.id], Nuntius::Message.where(nuntiable: plain_account).pluck(:template_id)
      assert_equal plain_account, Nuntius::Message.find_by(nuntiable: plain_account).account
    end
  end
end
