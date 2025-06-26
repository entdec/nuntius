# frozen_string_literal: true

require "test_helper"

class Nuntius::StateMachineTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "firing an event creates nuntius-events" do
    user = User.create!(name: "test", email: "test@example.com")
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
end
