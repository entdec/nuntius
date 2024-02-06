# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class ListsController < ApplicationAdminController
      def index
        @lists = Nuntius::List.visible.order(:name)
      end

      def new
        @list = Nuntius::List.new
        render :edit
      end

      def create
        @list = Nuntius::List.create(list_params)
        respond_with :admin, @list
      end

      def show
        redirect_to :edit_admin_list, status: :see_other
      end

      def edit
        @list = Nuntius::List.visible.find(params[:id])
      end

      def update
        @list = Nuntius::List.visible.find(params[:id])
        @list.update(list_params)
        respond_with :admin, @list
      end

      private

      def set_objects; end

      def list_params
        params.require(:list).permit(:name, :slug, :allow_unsubscribe, :description, :metadata_yaml)
      end
    end
  end
end
