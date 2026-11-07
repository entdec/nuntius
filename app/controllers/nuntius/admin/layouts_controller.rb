# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    class LayoutsController < ApplicationAdminController
      include Nuntius::EmailDesignParams

      def index
        @layouts = Nuntius::Layout.visible.order(:name)
      end

      def new
        @layout = Nuntius::Layout.new(json: Nuntius::Layout.starting_document(params[:start]))
        render :edit
      end

      def create
        @layout = Nuntius::Layout.new(layout_params)
        assign_layout_design
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
        @layout.assign_attributes(layout_params)
        assign_layout_design
        @layout.save
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
        params.require(:layout).permit(:name, :metadata_yaml)
      end

      def assign_layout_design
        design = design_params(:layout)
        @layout.assign_attributes(json: design[:document], mjml: design[:mjml]) if design
      end
    end
  end
end
