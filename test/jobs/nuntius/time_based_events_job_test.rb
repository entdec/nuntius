require "test_helper"
require "minitest/mock"

module Nuntius
  class TimeBasedEventsJobTest < ActiveJob::TestCase
    setup do
    end

    test "will only send out messages when due" do
      template1 = Nuntius::Template.create!(description: "template1", klass: "Account", transport: "mail", event: "after_created_at", to: "test@example.org", html: "Hello {{name}} - 5 days", interval: "5 days", created_at: 1.month.ago)
      template2 = Nuntius::Template.create!(description: "template2", klass: "Account", transport: "mail", event: "after_created_at", to: "test@example.org", html: "Hello {{name}} - 10 days", interval: "10 days", created_at: 1.month.ago)
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

      template = ->(description, owner, global = false) { Nuntius::Template.create!(description: description, klass: "Account", transport: "mail", event: "after_created_at", to: "test@example.org", html: "Hello {{name}} - #{description}", interval: "5 days", created_at: 1.month.ago, account: owner, global: global) }
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

    test "a birthday every year: for users older than the template, once a day" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        user = User.create!(name: "Juliet", email: "juliet@example.org", born_on: Date.new(1990, 4, 7), created_at: 5.years.ago)
        Nuntius::Template.create!(description: "birthday", klass: "User", transport: "mail", event: "before_born_on", interval: "4 weeks", recurrence: "yearly", to: "{{ user.email }}", html: "Soon!")

        run_job 2
        assert_equal 1, Nuntius::Message.where(nuntiable: user).count

        travel 1.day
        run_job
        assert_equal 1, Nuntius::Message.where(nuntiable: user).count
      end

      # and again the next year
      travel_to Time.zone.local(2028, 3, 10, 10) do
        run_job 2
        assert_equal 2, Nuntius::Message.where(nuntiable: User.find_by(email: "juliet@example.org")).count
      end
    end

    # Mail mustn't go out more than once: every kind of timebased template,
    # with the job running again (as cron does) while it's still due

    test "an event after an interval: once, however often the job runs while it's due" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        template = template!(klass: "Account", event: "after_created_at", interval: "5 days")
        account = Account.create!(name: "new", created_at: 5.days.ago - 30.minutes)

        run_job 2
        travel 10.minutes
        run_job

        assert_equal 1, sent(template, account)
      end
    end

    test "a time, once: in the hour it's due, however often the job runs" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        template = template!(klass: "User", event: "after_activated_at", interval: "2 hours", to: "{{ user.email }}")
        user = user!(activated_at: 2.hours.ago - 10.minutes)

        run_job 2
        travel 30.minutes
        run_job

        assert_equal 1, sent(template, user)
      end
    end

    test "a date, once: on its day from the send hour, and only once" do
      travel_to Time.zone.local(2027, 3, 10, 8) do
        template = template!(klass: "User", event: "before_born_on", interval: "4 days", to: "{{ user.email }}")
        user = user!(born_on: Date.new(2027, 3, 14))

        run_job
        assert_equal 0, sent(template, user), "not before the send hour"

        travel 2.hours
        run_job 2
        travel 5.hours
        run_job
        assert_equal 1, sent(template, user)

        travel 1.day
        run_job
        assert_equal 1, sent(template, user), "nor the day after"
      end
    end

    test "every month: on the day each month, once that day" do
      template = nil
      user = nil
      travel_to Time.zone.local(2027, 1, 15, 10) do
        template = template!(klass: "User", event: "before_born_on", interval: "0 days", recurrence: "monthly", to: "{{ user.email }}")
        user = user!(born_on: Date.new(2026, 11, 15))

        run_job 2
        travel 3.hours
        run_job
        assert_equal 1, sent(template, user)

        travel 1.day
        run_job
        assert_equal 1, sent(template, user)
      end

      travel_to Time.zone.local(2027, 2, 15, 9, 5) do
        run_job 2
        assert_equal 2, sent(template, user)
      end
    end

    test "conditions: nothing while they aren't met, then once" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        template = template!(klass: "User", event: "before_born_on", interval: "0 days", recurrence: "yearly", to: "{{ user.email }}",
          conditions: {"match" => "all", "rules" => [{"variable" => "user.state", "operator" => "is", "value" => "active"}]})
        user = user!(born_on: Date.new(1990, 3, 10), state: "pending")

        run_job 2
        assert_equal 0, sent(template, user)

        user.update!(state: "active")
        run_job 2
        assert_equal 1, sent(template, user)
      end
    end

    test "a date, once: also for objects older than the template" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        user = user!(born_on: Date.new(2027, 3, 14), created_at: 2.years.ago)
        template = template!(klass: "User", event: "before_born_on", interval: "4 days", to: "{{ user.email }}", created_at: Time.current)

        run_job 2
        assert_equal 1, sent(template, user)
      end
    end

    test "a template whose event isn't around a timestamp (a timebased_scope's) sends nothing" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        template = template!(klass: "Account", event: "after_created", interval: "5 days")
        account = Account.create!(name: "new", created_at: 5.days.ago - 30.minutes)

        log = StringIO.new
        Nuntius.config.stub(:logger, Logger.new(log)) { run_job }

        assert_equal 0, sent(template, account)
        assert_match(/template #{template.id} \(Account after_created\) has an interval, but after_created isn't around a timestamp/, log.string)
      end
    end

    test "a template that would send more than its limit sends nothing, and is held" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        template = template!(klass: "User", event: "before_born_on", interval: "0 days", recurrence: "yearly", to: "{{ user.email }}", timebased_limit: 2)
        users = 3.times.map { |i| user!(email: "user#{i}@example.org", born_on: Date.new(1990, 3, 10)) }

        log = StringIO.new
        assert_error_reported(TimebasedEventsJob::LimitExceeded) do
          Nuntius.config.stub(:logger, Logger.new(log)) { run_job }
        end

        assert_equal 0, users.sum { |user| sent(template, user) }
        assert_not template.reload.enabled
        assert_match(/would send more than 2 messages, so it's disabled/, log.string)

        run_job
        assert_equal 0, users.sum { |user| sent(template, user) }, "nor once it's disabled"
      end
    end

    test "the limit counts the messages after the conditions, and up to it a template sends" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        template = template!(klass: "User", event: "before_born_on", interval: "0 days", recurrence: "yearly", to: "{{ user.email }}", timebased_limit: 2,
          conditions: {"match" => "all", "rules" => [{"variable" => "user.state", "operator" => "is", "value" => "active"}]})
        active = 2.times.map { |i| user!(email: "active#{i}@example.org", born_on: Date.new(1990, 3, 10), state: "active") }
        3.times { |i| user!(email: "pending#{i}@example.org", born_on: Date.new(1990, 3, 10), state: "pending") }

        run_job

        assert_equal [1, 1], active.map { |user| sent(template, user) }
        assert_equal 2, Nuntius::Message.where(template: template).count
        assert template.reload.enabled
      end
    end

    test "a run while another one is running sends nothing, so they can't both send" do
      travel_to Time.zone.local(2027, 3, 10, 10) do
        template = template!(klass: "Account", event: "after_created_at", interval: "5 days")
        account = Account.create!(name: "new", created_at: 5.days.ago - 30.minutes)

        other_run = PG.connect(ActiveRecord::Base.connection.raw_connection.conninfo_hash.reject { |_, value| value.blank? })
        begin
          other_run.exec("SELECT pg_advisory_lock(#{TimebasedEventsJob::LOCK})")
          run_job
          assert_equal 0, sent(template, account)
        ensure
          other_run.close
        end

        run_job
        assert_equal 1, sent(template, account)
      end
    end

    test "a run lets go of its lock, also when it has nothing to send" do
      template!(klass: "Account", event: "after_created_at", interval: "5 days")
      run_job 3

      other_run = PG.connect(ActiveRecord::Base.connection.raw_connection.conninfo_hash.reject { |_, value| value.blank? })
      begin
        assert_equal "t", other_run.exec("SELECT pg_try_advisory_lock(#{TimebasedEventsJob::LOCK})").getvalue(0, 0)
      ensure
        other_run.close
      end
    end

    private

    def run_job(times = 1)
      times.times do
        perform_enqueued_jobs only: [Nuntius::MessengerJob, Nuntius::TimebasedEventsJob] do
          Nuntius::TimebasedEventsJob.perform_now
        end
      end
    end

    # Global, and older than the objects it's sent for
    def template!(**attributes)
      Nuntius::Template.create!(description: "timebased", transport: "mail", to: "test@example.org", html: "Hello",
        global: true, created_at: 1.year.ago, **attributes)
    end

    def user!(**attributes)
      User.create!(name: "Romeo", email: "romeo@example.org", account: accounts(:one), **attributes)
    end

    def sent(template, object)
      Nuntius::Message.where(template: template, nuntiable: object).count
    end
  end
end
