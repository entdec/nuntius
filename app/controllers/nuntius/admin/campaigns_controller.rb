# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class CampaignsController < ApplicationAdminController

      before_action :set_objects, except: [:index]
      add_breadcrumb I18n.t('nuntius.breadcrumbs.admin.campaigns'), :admin_campaigns_path

      def index
        @campaigns = Campaign.all
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

      def edit
        @lists = List.all
      end

      def update
        respond @campaign.update(campaign_params)
      end

      private

      def set_objects
        @campaign = if params[:id]
                     Campaign.find(params[:id])
                   else
                     params[:campaign] ? Campaign.new(campaign_params) : Campaign.new
                   end
      end

      def campaign_params
        params.require(:campaign).permit(:name)
      end

    end
  end
end
