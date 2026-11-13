# frozen_string_literal: true

require "test_helper"

module Nuntius
  class CampaignTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper

    test "a draft, scheduled or sending campaign can be cancelled, a sent one not" do
      campaign = nuntius_campaigns(:valentines_day)
      assert campaign.cancel
      assert campaign.reload.cancelled?
      assert_not campaign.can_schedule?

      campaign.update_column(:state, "scheduled")
      assert campaign.cancel

      campaign.update_column(:state, "sending")
      assert campaign.cancel

      campaign.update_column(:state, "sent")
      assert_not campaign.cancel
      assert campaign.reload.sent?
    end

    test "a campaign is designed without a list, but not scheduled without one" do
      campaign = Campaign.create!(name: "News", transport: "sms", text: "Hi", account: accounts(:one))

      assert_not campaign.can_schedule?
      campaign.update!(list: nuntius_lists(:valentines))
      assert campaign.can_schedule?
    end

    test "a cancelled campaign stops sending" do
      campaign = nuntius_campaigns(:valentines_day)
      campaign.update_column(:state, "cancelled")

      DeliverCampaignService.perform(campaign: campaign)

      assert_empty campaign.messages
      assert campaign.reload.cancelled?
    end

    test "a scheduled campaign goes back to draft when it's descheduled" do
      campaign = nuntius_campaigns(:valentines_day)
      assert_not campaign.can_publish?

      assert campaign.schedule
      assert campaign.reload.scheduled?
      assert campaign.deschedule
      assert campaign.reload.draft?
      assert_not campaign.deschedule
    end

    test "scheduling enqueues the publish job in a minute" do
      freeze_time do
        assert_enqueued_with(job: CampaignPublishJob, at: 1.minute.from_now) { nuntius_campaigns(:valentines_day).schedule! }
      end
    end

    test "the publish job publishes the scheduled campaigns that are due, not drafts" do
      due = nuntius_campaigns(:valentines_day)
      due.update_columns(state: "scheduled", publish_at: 1.hour.ago)
      later = nuntius_campaigns(:xmas)
      later.update_columns(state: "scheduled", publish_at: 1.hour.from_now)
      draft = Nuntius::Campaign.create!(name: "Draft", transport: "sms", list: due.list, publish_at: 1.hour.ago)

      assert_enqueued_jobs 1 do
        CampaignPublishJob.perform_now
      end

      assert due.reload.sending?
      assert later.reload.scheduled?
      assert draft.reload.draft?
    end

    test "the publish job publishes a scheduled campaign without a publish time right away" do
      campaign = nuntius_campaigns(:valentines_day)
      campaign.update_columns(state: "scheduled", publish_at: nil)

      CampaignPublishJob.perform_now

      assert campaign.reload.sending?
    end
  end
end
