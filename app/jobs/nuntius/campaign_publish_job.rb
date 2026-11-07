module Nuntius
  # Publishes the scheduled campaigns that are due: their publish_at has
  # passed, or they don't have one
  class CampaignPublishJob < ApplicationJob
    def perform
      due = Nuntius::Campaign.where(state: :scheduled)
      due = due.where(publish_at: nil).or(due.where(publish_at: ..Time.current))
      due.find_each do |campaign|
        # Reloads it, so a campaign descheduled or published in the meantime is left alone
        campaign.with_lock { campaign.publish! if campaign.scheduled? }
      end
    end
  end
end
