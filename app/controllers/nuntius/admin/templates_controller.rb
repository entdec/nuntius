# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class TemplatesController < ApplicationAdminController
      before_action :set_objects, except: [:index]
      before_action :set_template_and_version, only: [:rollback]

      def index
        @templates = Nuntius::Template.visible.order(:description)
      end

      def new
        @template = Nuntius::Template.new
        render :edit
      end

      def create
        @template = Nuntius::Template.new(template_params)
        @template.save
        respond_with :admin, @template, action: :edit
      end

      def edit
        @template = Nuntius::Template.visible.find(params[:id])
      end

      def show
        redirect_to :edit_admin_template, status: :see_other
      end

      def update
        @template = Nuntius::Template.visible.find(params[:id])
        @template.update(template_params)
        PaperTrail::Version.where('created_at < ?', 1.year.ago).delete_all
        respond_with :admin, @template
      end

      def destroy
        @template = Nuntius::Template.visible.find(params[:id])
        @template.destroy
        respond_with :admin, @template
      end

      def rollback
        reverted_template = @version.reify
        @template.update(reverted_template.attributes)
        respond_with :admin, @template
      end

      private

      def set_template_and_version
        @template = Nuntius::Templates.find(params[:id])
        @version = @template.versions.find(params[:version_id])
      end

      def set_objects
        @layouts = Nuntius::Layout.visible
      end

      def template_params
        params.require(:template).permit(:enabled, :klass, :event, :interval, :transport, :description, :metadata_yaml, :payload, :from, :to, :subject, :layout_id, :html, :text, :payload)
      end
    end
  end
end
