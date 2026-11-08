# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    class TemplatesController < ApplicationAdminController
      include Nuntius::EmailDesignParams

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
        assign_email_design(@template, :template) if @template.email?
        @template.save(context: :admin)
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
        @template.assign_attributes(template_params)
        assign_email_design(@template, :template) if @template.email?
        # Images uploaded on the Media tab
        images = Array(params.dig(:template, :images)).compact_blank
        @template.images.attach(images) if @template.save(context: :admin) && images.any?
        respond_with :admin, @template
      end

      # Converts a template with an old layout into the email editor
      def convert
        @template = Nuntius::Template.visible.find(params[:id])
        layout = @layouts.find_by(id: params.dig(:template, :layout_id))
        if Nuntius::TemplateConversion.new(@template, layout).convert
          redirect_to edit_admin_template_path(@template), notice: t(".converted"), status: :see_other
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @template = Nuntius::Template.visible.find(params[:id])
        @template.destroy
        respond_with :admin, @template
      end

      private

      def set_objects
        @layouts = Nuntius::Layout.visible
      end

      def template_params
        permitted = %i[enabled auto_description klass event based_on timestamp direction interval interval_amount interval_unit recurrence timebased_limit transport description payload from to subject layout_id html text link_tracking open_tracking]
        permitted << :global if Nuntius.config.can_create_global
        # Old layouts read their values from the template's metadata
        permitted << :metadata_yaml if @template&.old_layout
        params.require(:template).permit(*permitted, conditions: [:match, rules: %i[variable operator value value_to]])
      end
    end
  end
end
