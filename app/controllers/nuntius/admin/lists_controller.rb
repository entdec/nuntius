# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class ListsController < ApplicationAdminController

      add_breadcrumb I18n.t('nuntius.breadcrumbs.admin.lists'), :admin_lists_path

      def index
        @lists = List.all
      end

      def new
        @list = List.new
        render :edit
      end

      def create
        @list = List.new(list_params)
        flash_and_redirect @list.save, admin_lists_url, 'List created successfully', 'There were problems creating the list'
      end

      def show
        redirect_to :edit_admin_list
      end

      def edit
        @list = List.find(params[:id])
      end

      def update
        @list = List.find(params[:id])
        flash_and_redirect @list.update(list_params), admin_lists_url, 'List updated successfully', 'There were problems updating the list'
      end

      private

      def set_objects

      end

      def list_params
        params.require(:list).permit(:name)
      end

    end
  end
end
