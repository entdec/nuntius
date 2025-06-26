# frozen_string_literal: true

module Nuntius
  class MessagesTable < Nuntius::ApplicationTable

    definition do
      model Nuntius::Message

      column(:to)
      column(:created_at)
      column(:last_sent_at)
      action :resend do
        link { |message| nuntius.resend_admin_message_path(message) }
        icon "fal fa-rotate-right"
        link_attributes data: {"turbo-confirm": "Are you sure you want to resend the message?", "turbo-method": :post}
        show ->(message) { true }
      end
      
      column(:campaign_id) do
        render do
          html do |message|
            link_to message.campaign&.name, nuntius.edit_admin_campaign_path(message.campaign) if message.campaign
          end
        end
      end
      column(:template_id) do
        render do
          html do |message|
            link_to message.template&.description, nuntius.edit_admin_template_path(message.template) if message.template
          end
        end
      end
      column :nuntiable_type do
        internal true # Needed for related_object below
      end
      column :nuntiable_id do
        internal true # Needed for related_object below
      end
      column(:object) do # do |message|
        render do
          html do |message|
            if message.nuntiable
              link_to "#{message.nuntiable} (#{message.nuntiable_type})", begin
                url_for(message.nuntiable)
              rescue
                ""
              end
            end
          end
        end
      end
      column(:status)

      order created_at: :desc

      link { |message| nuntius.admin_message_path(message) }
    end

    private

    def scope
      @scope = Nuntius::Message.visible
      @scope = @scope.where(nuntiable_id: params[:nuntiable_id], nuntiable_type: params[:nuntiable_type]) if params[:nuntiable_id]
      @scope = @scope.where(template_id: params[:template_id]) if params[:template_id]
      @scope
    end
  end
end
