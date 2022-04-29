# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class MessagesController < ApplicationAdminController
      def index
        @messages = Nuntius::Message.visible.order(created_at: :desc)
        @messages = @messages.where(template_id: params[:template_id]) if params[:template_id]
      end

      def show
        @message = Nuntius::Message.visible.find(params[:id])
      end

      def resend
        @message = Nuntius::Message.visible.find(params[:id])
        @message.resend
        respond_with @message, success: t('.resend_success'), error: t('.resend_error')
      end
    end
  end
end
