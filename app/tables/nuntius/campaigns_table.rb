# frozen_string_literal: true

module Nuntius
  class CampaignsTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Campaign

      column(:name)
      column(:metadata) do
        render do
          html do |template|
            Nuntius.config.metadata_humanize(template.metadata)
          end
        end
      end
      column(:transport)
      column(:state)

      column(:list_name) do
        attribute "nuntius_lists.name"
      end

      action :publish do
        # FIXME: next unless campaign.can_publish?
        show ->(campaign) { campaign.transport != "sms" && campaign.can_publish? }
        link { |campaign| campaign.can_publish? ? nuntius.publish_admin_campaign_path(campaign) : nil }
        icon "fa-solid fa-paper-plane"
        link_attributes data: {"turbo-confirm": "Are you sure you want to send out this campaign?", "turbo-method": :post}
      end

      order name: :asc

      link { |campaign| nuntius.edit_admin_campaign_path(campaign) }
    end

    private

    def scope
      @scope = Nuntius::Campaign.visible.joins(:list)
    end
  end
end
