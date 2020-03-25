# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class MessagesController < ApplicationAdminController
      add_breadcrumb(I18n.t('nuntius.breadcrumbs.admin.messages'), :admin_messages_path) if defined? add_breadcrumb

      def index
        @messages = Nuntius::Message.visible.order(created_at: :desc)
        if params[:template_id]
          @messages = @messages.where(template_id: params[:template_id])
        end
      end

      def show
        @message = Nuntius::Message.visible.find(params[:id])
        add_breadcrumb(@message.id, admin_message_path(@message)) if defined? add_breadcrumb
      end

      def resend
        @message = Nuntius::Message.visible.find(params[:id])
        @message.resend
        render :show
      end
    end
  end
end
