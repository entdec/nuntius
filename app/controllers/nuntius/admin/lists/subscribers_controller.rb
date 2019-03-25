# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    module Lists
      class SubscribersController < ApplicationAdminController
        before_action :set_objects

        def index
          @subscribers = @list.subscribers.all
        end

        def new
          @subscriber = @list.subscribers.new
          render :edit
        end

        def create
          @subscriber = @list.subscribers.new(subscriber_params)
          flash_and_redirect @subscriber.save, admin_list_url(@list), 'Subscriber created successfully', 'There were problems creating the subscriber'
        end

        def edit
          @subscriber = @list.subscribers.find(params[:id])
        end

        def update
          @subscriber = @list.subscribers.find(params[:id])
          flash_and_redirect @subscriber.update(subscriber_params), admin_list_subscribers_url(@list), 'Subscriber updated successfully', 'There were problems updating the subscriber'
        end

        private

        def subscriber_params
          params.require(:subscriber).permit(:first_name, :last_name, :email, :phone_number, tags: [])
        end

        def set_objects
          @list = List.find(params[:list_id])

          add_breadcrumb I18n.t('nuntius.breadcrumbs.admin.lists'), :admin_lists_path
          add_breadcrumb(@list.name, edit_admin_list_path(@list))
          # add_breadcrumb I18n.t('nuntuis.breadcrumbs.admin.subscribers'), admin_list_subscribers_path(@subscriber)
        end

      end
     end
  end
end
