# frozen_string_literal: true

module Nuntius
  class CampaignMessagesTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Message

      column(:to)
      column(:status)
      column(:created_at)

      order created_at: :desc

      link { |message| nuntius.admin_message_path(message) }
    end

    private

    def scope
      @scope = Nuntius::Campaign.find_by(params[:campaign_id]).messages
      @scope
    end
  end
end
