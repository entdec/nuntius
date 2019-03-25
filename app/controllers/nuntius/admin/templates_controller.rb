# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class TemplatesController < ApplicationAdminController

      add_breadcrumb I18n.t('nuntius.breadcrumbs.admin.templates'), :admin_templates_path

      def index
        @templates = Template.all
      end

      def new
        @template = Template.new
        render :edit
      end

      def create
        @template = Template.new(template_params)
        respond @template.save
      end

      def edit
        @template = Template.find(params[:id])
      end

      def update
        @template = Template.find(params[:id])
        respond @template.update(template_params)
      end

      private

      def template_params
        params.require(:template).permit(:klass, :event, :transport, :description, :metadata, :from, :to, :subject, :html, :text, :payload).tap do |w|
          w[:metadata] = YAML.safe_load(params[:template][:metadata])
        end
      end

    end
  end
end
