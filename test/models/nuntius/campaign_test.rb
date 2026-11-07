# frozen_string_literal: true

require "test_helper"

module Nuntius
  class CampaignTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    test "a draft or sending campaign can be cancelled, a sent one not" do
      campaign = nuntius_campaigns(:valentines_day)
      assert campaign.cancel
      assert campaign.reload.cancelled?
      assert_not campaign.can_publish?

      campaign.update_column(:state, "sending")
      assert campaign.cancel

      campaign.update_column(:state, "sent")
      assert_not campaign.cancel
      assert campaign.reload.sent?
    end

    test "a cancelled campaign stops sending" do
      campaign = nuntius_campaigns(:valentines_day)
      campaign.update_column(:state, "cancelled")

      DeliverCampaignService.perform(campaign: campaign)

      assert_empty campaign.messages
      assert campaign.reload.cancelled?
    end

    test "the publish job publishes the draft campaigns that are due" do
      due = nuntius_campaigns(:valentines_day)
      due.update_column(:publish_at, 1.hour.ago)
      later = nuntius_campaigns(:xmas)
      later.update_column(:publish_at, 1.hour.from_now)

      assert_enqueued_jobs 1 do
        CampaignPublishJob.perform_now
      end

      assert due.reload.sending?
      assert later.reload.draft?
    end
  end
end
