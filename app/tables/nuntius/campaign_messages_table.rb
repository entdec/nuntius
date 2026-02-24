# frozen_string_literal: true

module Nuntius
  class CampaignMessagesTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Message

      column(:to)
      column(:status)
      column(:created_at)
      column(:last_sent_at)
      action :resend do
        link { |message| nuntius.resend_admin_message_path(message) }
        icon "fal fa-rotate-right"
        link_attributes data: {"turbo-confirm": "Are you sure you want to resend the message?", "turbo-method": :post}
        show ->(message) { true }
      end
      column(:open_count)
      column(:click_count)

      order created_at: :desc

      link { |message| nuntius.admin_message_path(message) }
    end

    private

    def scope
      @scope = Nuntius::Campaign.find(params[:campaign_id]).messages
      @scope
    end
  end
end
