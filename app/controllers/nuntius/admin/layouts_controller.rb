# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class LayoutsController < ApplicationAdminController

      add_breadcrumb I18n.t('nuntius.breadcrumbs.admin.layouts'), :admin_layouts_path

      def index
        @layouts = Nuntius::Layout.visible
      end

      def new
        @layout = Nuntius::Layout.new
        render :edit
      end

      def create
        @layout = Nuntius::Layout.new(layout_params)
        respond @layout.save
      end

      def edit
        @layout = Nuntius::Layout.visible.find(params[:id])
      end

      def show
        redirect_to :edit_admin_layout
      end

      def update
        @layout = Nuntius::Layout.visible.find(params[:id])
        respond @layout.update(layout_params)
      end

      private

      def layout_params
        params.require(:layout).permit(:name, :data).tap do |w|
          w[:metadata] = YAML.safe_load(params[:layout][:metadata])
        end
      end
    end
  end
end
