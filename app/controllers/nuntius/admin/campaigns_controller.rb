# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class CampaignsController < ApplicationAdminController
      before_action :set_objects, except: [:index]

      def index
        @campaigns = Nuntius::Campaign.visible.order(created_at: :desc)
      end

      def new
        render :edit
      end

      def create
        @campaign.save
        respond_with :admin, @campaign, action: :edit
      end

      def show
        redirect_to :edit_admin_campaign, status: :see_other
      end

      def edit; end

      def update
        saved = @campaign.update(campaign_params)

        if saved && params[:commit] == 'send'
          @campaign.publish! if @campaign.can_publish?
          redirect_to :edit_admin_campaign, status: :see_other
        else
          respond_with :admin, @campaign
        end
      end

      private

      def set_objects
        @campaign = params[:id] ? Nuntius::Campaign.visible.find(params[:id]) : Nuntius::Campaign.new(campaign_params)
        @lists = Nuntius::List.visible
        @layouts = Nuntius::Layout.visible
        @messages = Nuntius::Message.where(campaign: @campaign)
      end

      def campaign_params
        return unless params[:campaign]

        params.require(:campaign).permit(:name, :transport, :layout_id, :list_id, :from, :subject, :text, :html)
      end
    end
  end
end
