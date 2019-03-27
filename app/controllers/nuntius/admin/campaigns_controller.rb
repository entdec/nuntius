# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class CampaignsController < ApplicationAdminController

      before_action :set_objects, except: [:index]
      add_breadcrumb I18n.t('nuntius.breadcrumbs.admin.campaigns'), :admin_campaigns_path

      def index
        @campaigns = Campaign.visible
      end

      def new
        render :edit
      end

      def create
        respond @campaign.save
      end

      def show
        redirect_to :edit_admin_campaign
      end

      def edit; end

      def update
        respond @campaign.update(campaign_params)
      end

      private

      def set_objects
        @campaign = params[:id] ? Campaign.visible.find(params[:id]) : Campaign.new(campaign_params)
        @lists = List.visible
      end

      def campaign_params
        return unless params[:campaign]

        params.require(:campaign).permit(:name, :tranport, :list_id, :from, :subject, :text, :html)
      end
    end
  end
end