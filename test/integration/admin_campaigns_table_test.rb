# frozen_string_literal: true

require "test_helper"

class AdminCampaignsTableTest < ActionDispatch::IntegrationTest
  test "the table has the campaigns without a list too" do
    Nuntius::Campaign.create!(name: "Unlisted", transport: "sms", text: "Hi", account: accounts(:one))

    get "/mensa/tables/nuntius%2Fcampaigns", params: {turbo_frame_id: "campaigns"}

    assert_response :success
    assert_includes response.body, "Unlisted"
    assert_includes response.body, nuntius_campaigns(:valentines_day).name
  end
end
