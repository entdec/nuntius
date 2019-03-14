# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class Admin::MessagesController < ApplicationAdminController
      before_action :set_objects, except: %i[index create destroy]
      authorize_resource

      add_breadcrumb I18n.t('breadcrumbs.admin.messages'), :admin_messages_path

      def new
        @message = current_channel.messages.new
        render :edit
      end

      def create
        @message = current_channel.messages.new(message_params)
        flash_and_redirect @message.save, admin_messages_url, 'Message created successfully', 'There were problems creating the message'
      end

      def index;
      end

      def show
        redirect_to :edit_admin_message
      end

      def edit
        @message = Message.accessible_for(current_user).find(params[:id])
        add_breadcrumb I18n.t('breadcrumbs.edit'), edit_admin_message_path(@message)
      end

      def update
        @message = Message.accessible_for(current_user).find(params[:id])
        flash_and_redirect @message.update(message_params), admin_messages_url, 'Message updated successfully', 'There were problems updating the message'
      end

      def duplicate
        message = Message.accessible_for(current_user).find(params[:id])
        @message = message.amoeba_dup
        render :edit
      end

      def destroy
        @message = Message.accessible_for(current_user).find(params[:id])
        @message.destroy
        redirect_to admin_messages_url
      end

      private

      def set_objects
        @retailers = Retailer.accessible_for(current_user).order(:name)
        @companies = Company.accessible_for(current_user).order(:name)
        @layouts = Message.accessible_for(current_user)
      end

      def message_params
        params.require(:message).permit(:channel_id, :conditions, :query, :to, :kind, :klass,
                                        :event, :timestamp, :interval, :description, :subject,
                                        :html, :text, :layout_id, :filter, :retailer_id, :company_id, preview_ids: []).tap do |whitelisted|
          whitelisted[:preview_ids] = [*params[:message][:preview_ids]].reject(&:empty?)
          whitelisted[:query] = JSON.parse(whitelisted[:query]) if whitelisted[:query]
        end
      end
    end
  end
end
