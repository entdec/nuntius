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

      # What to send, and for an email which layout to start from, as cards
      # (new.html.slim); once chosen, the editor for a new template, which its
      # first save creates. Only one to choose from is chosen already.
      def new
        @transports = helpers.nuntius_transports
        transport = params[:transport].presence_in(@transports) || (@transports.first if @transports.one?)
        layout = @layouts.find_by(id: params[:layout_id]) || (@layouts.first if @layouts.one?)
        if transport.nil? || (transport == "mail" && layout.nil?)
          @transport = transport
          return render(:new)
        end

        @template = Nuntius::Template.new(transport: transport, layout: (layout if transport == "mail"))
        @template.start_design
        # Back to the choice it was made from, when there was one
        @back_path = if transport == "mail" && @layouts.many?
          new_admin_template_path(transport: "mail")
        elsif @transports.many?
          new_admin_template_path
        end
        render :edit
      end

      def create
        @template = Nuntius::Template.new(template_params)
        assign_design
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
        assign_design
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

      # The preview in the editor of an SMS, Push, Teams, Slack or Voice
      # template, with sample values (TemplatePreview)
      def preview
        template = Nuntius::Template.new(params.require(:template).permit(:transport, :klass, :text, :payload))
        render json: Nuntius::TemplatePreview.new(template).to_h
      end

      def destroy
        @template = Nuntius::Template.visible.find(params[:id])
        @template.destroy
        respond_with :admin, @template
      end

      private

      # What its editor submits: the email editor's, or the message editor's document
      def assign_design
        if @template.email?
          assign_email_design(@template, :template)
        elsif @template.message_design? && (document = params.dig(:template, :design_json)).present?
          @template.assign_message_design(document)
        end
      end

      def set_objects
        @layouts = Nuntius::Layout.visible
      end

      def template_params
        permitted = %i[enabled auto_description klass event based_on timestamp direction interval interval_amount interval_unit recurrence timebased_limit transport description payload from to subject layout_id html text link_tracking open_tracking]
        permitted << :global if Nuntius.config.can_create_global
        # What it sends is chosen when it's made (see new)
        permitted.delete(:transport) if @template&.persisted?
        # Old layouts read their values from the template's metadata
        permitted << :metadata_yaml if @template&.old_layout
        params.require(:template).permit(*permitted, conditions: [:match, rules: %i[variable operator value value_to]])
      end
    end
  end
end
