# frozen_string_literal: true

require "test_helper"

class Nuntius::StateMachineTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "firing an event creates nuntius-events" do
    user = User.create!(name: "test", email: "test@example.com")
    Nuntius::Template.create!(description: "template2", klass: "User", transport: "mail", event: "activate", to: "test@example.org", html: "Hello {{name}} - 10 days")

    assert_equal "pending", user.state

    perform_enqueued_jobs(only: [Nuntius::MessengerJob]) do
      User.transaction do
        user.activate!
      end
    end
    assert_performed_jobs 1

    assert_equal "active", user.state
    assert_equal 0, Nuntius::Event.count
  end

  test "firing an multiple event in multiple transaction creates nuntius-events " do
    user = User.create!(name: "test", email: "test@example.com")
    Nuntius::Template.create!(description: "template2", klass: "User", transport: "mail", event: "activate", to: "test@example.org", html: "Hello {{name}} - 10 days")

    assert_equal "pending", user.state

    perform_enqueued_jobs(only: [Nuntius::MessengerJob]) do
      User.transaction do
        user.activate!
      end
      User.transaction do
        user.disable!
      end
      User.transaction do
        user.activate!
      end
      User.transaction do
        user.save!
      end
    end
    assert_performed_jobs 2

    assert_equal "active", user.state
    assert_equal 0, Nuntius::Event.count
  end

  test "firing multiple event in single transaction creates nuntius-events " do
    user = User.create!(name: "test", email: "test@example.com")
    Nuntius::Template.create!(description: "template2", klass: "User", transport: "mail", event: "activate", to: "test@example.org", html: "Hello {{name}} - 10 days")

    assert_equal "pending", user.state

    perform_enqueued_jobs(only: [Nuntius::MessengerJob]) do
      User.transaction do
        user.activate!
        user.disable!
        user.activate!
        user.update!(name: "test user")
      end
    end
    assert_performed_jobs 1

    assert_equal "active", user.state
    assert_equal 0, Nuntius::Event.count
  end

  test "firing multiple event in single transaction multiple obj creates nuntius-events " do
    user = User.create!(name: "test", email: "test@example.com")
    report = Report.create!(name: "test report", email: "test@example.com")

    Nuntius::Template.create!(description: "template2", klass: "User", transport: "mail", event: "activate", to: "test@example.org", html: "Hello {{name}} - 10 days")

    assert_equal "pending", user.state

    perform_enqueued_jobs(only: [Nuntius::MessengerJob]) do
      User.transaction do
        user.activate!
        user.disable!
        report.activate!
        user.activate!
        user.update!(name: "test user")
      end
    end
    assert_performed_jobs 1

    assert_equal "active", user.state
    assert_equal 0, Nuntius::Event.count
  end

  test "firing multiple event in single transaction multiple obj and templates nuntius-events " do
    user = User.create!(name: "test", email: "test@example.com")
    report = Report.create!(name: "test report", email: "test@example.com")

    Nuntius::Template.create!(description: "template2", klass: "User", transport: "mail", event: "activate", to: "test@example.org", html: "Hello {{name}} - 10 days")
    Nuntius::Template.create!(description: "template2", klass: "Report", transport: "mail", event: "activate", to: "test@example.org", html: "Hello {{name}} - 10 days")

    assert_equal "pending", user.state

    perform_enqueued_jobs(only: [Nuntius::MessengerJob]) do
      User.transaction do
        user.activate!
        user.disable!
        report.activate!
        user.activate!
        user.update!(name: "test user")
      end
    end
    assert_performed_jobs 2

    assert_equal "active", user.state
    assert_equal 0, Nuntius::Event.count
  end
end
