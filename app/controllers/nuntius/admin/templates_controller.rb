# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class TemplatesController < ApplicationAdminController
      before_action :set_objects, except: [:index]
      add_breadcrumb(I18n.t('nuntius.breadcrumbs.admin.templates'), :admin_templates_path) if defined? add_breadcrumb

      def index
        @templates = Nuntius::Template.visible.order(:description)
      end

      def new
        @template = Nuntius::Template.new
        render :edit
      end

      def create
        @template = Nuntius::Template.new(template_params)
        respond @template.save
      end

      def edit
        @template = Nuntius::Template.visible.find(params[:id])
      end

      def show
        redirect_to :edit_admin_template
      end

      def update
        @template = Nuntius::Template.visible.find(params[:id])
        respond @template.update(template_params), action: :edit
      end

      def destroy
        @template = Nuntius::Template.visible.find(params[:id])
        respond @template.destroy, notice: 'The template was deleted', error: 'There were problems deleting the template'
      end

      private

      def set_objects
        @layouts = Nuntius::Layout.visible
      end

      def template_params
        params.require(:template).permit(:enabled, :klass, :event, :transport, :description, :metadata, :from, :to, :subject, :layout_id, :html, :text, :payload).tap do |w|
          w[:metadata] = YAML.safe_load(params[:template][:metadata])
          w[:payload] = YAML.safe_load(params[:template][:payload])
        end
      end
    end
  end
end
