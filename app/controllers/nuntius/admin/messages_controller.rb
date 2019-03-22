# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class Admin::MessagesController < ApplicationAdminController
      add_breadcrumb I18n.t('nuntius.breadcrumbs.admin.messages'), :admin_messages_path

      def index
        @messages = Message.all
      end

      def show
        @message = Message.find(params[:id])
        add_breadcrumb(@message.id, admin_message_path(@message)) if defined? add_breadcrumb
      end

    end
  end
end
