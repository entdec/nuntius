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
        flash_and_redirect @template.save, admin_templates_url, 'Template created successfully', 'There were problems creating the template'
      end

      private

      def template_params
        params.require(:template).permit(:klass, :event, :transport, :description, :metadata, :from, :to, :subject, :html, :text, :payload)
      end

    end
  end
end
