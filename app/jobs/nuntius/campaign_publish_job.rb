module Nuntius
  class CampaignPublishJob < ApplicationJob
    def perform
      Nuntius::Campaign.where(state: :draft, publish_at: ..Time.current).each do |campaign|
        @campaign.publish! if @campaign.can_publish?
      end
    end
  end
end
