# frozen_string_literal: true

module Nuntius
  class CampaignsTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Campaign

      column(:name)
      column(:transport)
      column(:state) do
        filter do
          collection -> { Nuntius::Campaign.state_machine.states.map(&:name).map(&:to_s) }
          multiple true
        end
      end

      column(:list_name) do
        attribute "nuntius_lists.name"
      end

      action :schedule do
        show ->(campaign) { campaign.transport != "sms" && campaign.can_schedule? }
        link { |campaign| nuntius.schedule_admin_campaign_path(campaign) }
        icon "fa-solid fa-paper-plane"
        link_attributes data: {"turbo-confirm": t(".campaign_schedule_confirm"), "turbo-method": :post}
      end

      action :deschedule do
        show ->(campaign) { campaign.can_deschedule? }
        link { |campaign| nuntius.deschedule_admin_campaign_path(campaign) }
        icon "fa-solid fa-calendar-xmark"
        link_attributes data: {"turbo-method": :post}
      end

      action :cancel do
        show ->(campaign) { campaign.can_cancel? }
        link { |campaign| nuntius.cancel_admin_campaign_path(campaign) }
        icon "fa-solid fa-ban"
        link_attributes data: {"turbo-confirm": t(".campaign_cancel_confirm"), "turbo-method": :post}
      end

      order name: :asc

      view :default do
        name -> { I18n.t("nuntius.tables.campaigns.views.open") }
        filter :state do
          operator :is
          value %w[draft scheduled]
        end
      end
      view :sent do
        name -> { I18n.t("nuntius.tables.campaigns.views.sent") }
        filter :state do
          operator :is
          value %w[sending sent]
        end
      end
      view :cancelled do
        name -> { I18n.t("nuntius.tables.campaigns.views.cancelled") }
        filter :state do
          operator :is
          value "cancelled"
        end
      end

      link { |campaign| nuntius.edit_admin_campaign_path(campaign) }
    end

    private

    def scope
      @scope = Nuntius::Campaign.visible.joins(:list)
    end
  end
end
