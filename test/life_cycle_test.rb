# frozen_string_literal: true

require "test_helper"

class Nuntius::LifeCycleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "creating a user" do
    user = nil
    perform_enqueued_jobs(only: [Nuntius::MessengerJob]) do
      user = User.create!(name: "test", email: "test@example.com")
    end

    assert_performed_jobs 1

    assert_equal "pending", user.state
    assert_equal 0, Nuntius::Event.count
  end
end
