# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    class CampaignsController < ApplicationAdminController
      include Nuntius::EmailDesignParams

      before_action :set_objects, except: [:index]

      def index
        @campaigns = Nuntius::Campaign.visible.order(created_at: :desc)
      end

      def new
        render :edit
      end

      def create
        assign_email_design(@campaign, :campaign) if @campaign.email?
        @campaign.save(context: :admin)
        respond_with :admin, @campaign, action: :edit
      end

      def show
        redirect_to :edit_admin_campaign, status: :see_other
      end

      def edit
      end

      def update
        @campaign.assign_attributes(campaign_params)
        assign_email_design(@campaign, :campaign) if @campaign.email?
        # Images uploaded on the Media tab
        images = Array(params.dig(:campaign, :images)).compact_blank
        @campaign.images.attach(images) if @campaign.save(context: :admin) && images.any?

        respond_with :admin, @campaign, action: :edit
      end

      # CampaignPublishJob publishes it at its publish_at, or within a minute without one
      def schedule
        @campaign.schedule! if @campaign.can_schedule?

        redirect_to :admin_campaigns, status: :see_other
      end

      # Back to draft, to change it before it's published
      def deschedule
        @campaign.deschedule! if @campaign.can_deschedule?

        redirect_to :edit_admin_campaign, status: :see_other
      end

      # Stops a draft, scheduled or sending campaign, keeping the messages it sent so far
      def cancel
        @campaign.cancel! if @campaign.can_cancel?

        redirect_to :edit_admin_campaign, status: :see_other
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

        params.require(:campaign).permit(:name, :transport, :layout_id, :list_id, :from, :subject, :text, :html, :open_tracking, :link_tracking, :publish_at, conditions: [:match, rules: %i[variable operator value value_to]])
      end
    end
  end
end
