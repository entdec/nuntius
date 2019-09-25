# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class ListsController < ApplicationAdminController

      add_breadcrumb(I18n.t('nuntius.breadcrumbs.admin.lists'), :admin_lists_path) if defined? add_breadcrumb

      def index
        @lists = Nuntius::List.visible
      end

      def new
        @list = Nuntius::List.new
        render :edit
      end

      def create
        @list = Nuntius::List.new(list_params)
        respond @list.save
      end

      def show
        redirect_to :edit_admin_list
      end

      def edit
        @list = Nuntius::List.visible.find(params[:id])
      end

      def update
        @list = Nuntius::List.visible.find(params[:id])
        respond @list.update(list_params), action: :edit
      end

      private

      def set_objects; end

      def list_params
        params.require(:list).permit(:name)
      end
    end
  end
end
