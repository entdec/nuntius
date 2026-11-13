# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    class CampaignsController < ApplicationAdminController
      include Nuntius::EmailDesignParams

      before_action :set_objects, except: [:index]

      def index
        @campaigns = Nuntius::Campaign.visible.order(created_at: :desc)
      end

      # What to send, and for an email which layout to start from, as cards
      # (the template's, new.html.slim); once chosen, the editor for a new
      # campaign, which its first save creates. Only one to choose from is chosen already.
      def new
        @transports = helpers.nuntius_transports & Nuntius::Campaign::TRANSPORTS
        transport = params[:transport].presence_in(@transports) || (@transports.first if @transports.one?)
        layout = @layouts.find_by(id: params[:layout_id]) || (@layouts.first if @layouts.one?)
        if transport.nil? || (transport == "mail" && layout.nil?)
          @transport = transport
          return render(:new)
        end

        @campaign = Nuntius::Campaign.new(transport: transport, layout: (layout if transport == "mail"), list: (@lists.first if @lists.one?))
        @campaign.start_design
        # Back to the choice it was made from, when there was one
        @back_path = if transport == "mail" && @layouts.many?
          new_admin_campaign_path(transport: "mail")
        elsif @transports.many?
          new_admin_campaign_path
        end
        render :edit
      end

      def create
        assign_design
        @campaign.save(context: :admin)
        respond_with :admin, @campaign, action: :edit
      end

      def show
        redirect_to :edit_admin_campaign, status: :see_other
      end

      def edit
      end

      def update
        @campaign.assign_attributes(campaign_params)
        assign_design
        # Images uploaded on the Media tab
        images = Array(params.dig(:campaign, :images)).compact_blank
        @campaign.images.attach(images) if @campaign.save(context: :admin) && images.any?

        respond_with :admin, @campaign, action: :edit
      end

      # Saves the campaign and sends it to its list's test recipients
      def send_test
        @campaign.assign_attributes(campaign_params) if campaign_params
        assign_design
        return render(:edit, status: :unprocessable_entity) unless @campaign.save(context: :admin)

        if @campaign.list.nil?
          redirect_to :edit_admin_campaign, alert: t(".no_list"), status: :see_other
        elsif @campaign.list.subscribers.test_recipients.exists?
          messages = @campaign.send_test
          redirect_to :edit_admin_campaign, notice: t(".sent", count: messages.size, to: messages.map(&:to).to_sentence), status: :see_other
        else
          redirect_to :edit_admin_campaign, alert: t(".no_test_recipients", list: @campaign.list.name), status: :see_other
        end
      end

      # CampaignPublishJob publishes it at its publish_at, or within a minute without one
      def schedule
        @campaign.schedule! if @campaign.can_schedule?

        redirect_to :admin_campaigns, status: :see_other
      end

      # Back to draft, to change it before it's published
      def deschedule
        @campaign.deschedule! if @campaign.can_deschedule?

        redirect_to :edit_admin_campaign, status: :see_other
      end

      # Stops a draft, scheduled or sending campaign, keeping the messages it sent so far
      def cancel
        @campaign.cancel! if @campaign.can_cancel?

        redirect_to :edit_admin_campaign, status: :see_other
      end

      private

      # What its editor submits: the email editor's, or the message editor's document
      def assign_design
        if @campaign.email?
          assign_email_design(@campaign, :campaign)
        elsif @campaign.message_design? && (document = params.dig(:campaign, :design_json)).present?
          @campaign.assign_message_design(document)
        end
      end

      def set_objects
        @campaign = params[:id] ? Nuntius::Campaign.visible.find(params[:id]) : Nuntius::Campaign.new(campaign_params)
        @lists = Nuntius::List.visible
        @layouts = Nuntius::Layout.visible
        @messages = Nuntius::Message.where(campaign: @campaign)
      end

      def campaign_params
        return unless params[:campaign]

        permitted = %i[name transport layout_id list_id from subject text html open_tracking link_tracking publish_at]
        # What it sends is chosen when it's made (see new)
        permitted.delete(:transport) if @campaign&.persisted?
        params.require(:campaign).permit(*permitted, conditions: [:match, rules: %i[variable operator value value_to]])
      end
    end
  end
end
