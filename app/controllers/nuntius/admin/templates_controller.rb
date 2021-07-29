# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class TemplatesController < ApplicationAdminController
      before_action :set_objects, except: [:index]

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
        respond_with :admin, @template
      end

      def destroy
        @template = Nuntius::Template.visible.find(params[:id])
        @template.destroy
        respond_with @template
      end

      private

      def set_objects
        @layouts = Nuntius::Layout.visible
      end

      def template_params
        params.require(:template).permit(:enabled, :klass, :event, :interval, :transport, :description, :metadata_yaml, :payload, :from, :to, :subject, :layout_id, :html, :text, :payload)
      end
    end
  end
end
