# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class ListsController < ApplicationAdminController

      add_breadcrumb(I18n.t('nuntius.breadcrumbs.admin.lists'), :admin_lists_path) if defined? add_breadcrumb

      def index
        @lists = List.visible
      end

      def new
        @list = List.new
        render :edit
      end

      def create
        @list = List.new(list_params)
        respond @list.save
      end

      def show
        redirect_to :edit_admin_list
      end

      def edit
        @list = List.visible.find(params[:id])
      end

      def update
        @list = List.visible.find(params[:id])
        respond @list.update(list_params)
      end

      private

      def set_objects; end

      def list_params
        params.require(:list).permit(:name)
      end
    end
  end
end
