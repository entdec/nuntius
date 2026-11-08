# frozen_string_literal: true

require "test_helper"

class AdminCampaignTestMessagesTest < ActionDispatch::IntegrationTest
  def campaign
    @campaign ||= Nuntius::Campaign.create!(name: "News", transport: "sms", list: nuntius_lists(:valentines), text: "Hi {{ subscriber.first_name }}", account: accounts(:one))
  end

  test "a draft campaign has a button that saves it and sends it to the list's test recipients" do
    nuntius_subscribers(:romeo).update!(test_recipient: true)

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert_select "button[type=submit][formaction='/nuntius/admin/campaigns/#{campaign.id}/send_test']"

    patch "/nuntius/admin/campaigns/#{campaign.id}/send_test", params: {campaign: {name: "Newer"}}

    assert_redirected_to "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert_equal "Newer", campaign.reload.name
    assert_equal [nuntius_subscribers(:romeo)], campaign.test_messages.map(&:subscriber)
    assert_equal "Saved, and sent a test message to 1.", flash[:notice]
  end

  test "without test recipients nothing is sent" do
    patch "/nuntius/admin/campaigns/#{campaign.id}/send_test", params: {campaign: {name: "News"}}

    assert_redirected_to "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert flash[:alert]
    assert_empty campaign.test_messages
  end

  test "a subscriber can be made a test recipient" do
    subscriber = nuntius_subscribers(:romeo)

    patch "/nuntius/admin/lists/#{subscriber.list_id}/subscribers/#{subscriber.id}", params: {subscriber: {test_recipient: "1"}}

    assert subscriber.reload.test_recipient
  end
end
