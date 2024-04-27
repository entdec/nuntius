# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    class LayoutsController < ApplicationAdminController
      def index
        @layouts = Nuntius::Layout.visible.order(:name)
      end

      def new
        @layout = Nuntius::Layout.new
        render :edit
      end

      def create
        @layout = Nuntius::Layout.new(layout_params)
        @layout.save
        respond_with :admin, @layout
      end

      def edit
        @layout = Nuntius::Layout.visible.find(params[:id])
      end

      def show
        redirect_to :edit_admin_layout, status: :see_other
      end

      def update
        @layout = Nuntius::Layout.visible.find(params[:id])
        @layout.update(layout_params)
        if params[:layout][:attachments].present?
          params[:layout][:attachments].each do |attachment|
            @layout.attachments.attach(attachment)
          end
        end
        respond_with :admin, @layout
      end

      def destroy
        @layout = Nuntius::Layout.visible.find(params[:id])
        @layout.destroy
        respond_with @layout
      end

      private

      def layout_params
        permitted = %i[name data metadata_yaml]
        params.require(:layout).permit(permitted)
      end
    end
  end
end
