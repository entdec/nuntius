# frozen_string_literal: true

module Nuntius
  class MessagesTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Message

      column(:to)
      column(:created_at)
      column(:last_sent_at)
      column(:actions) do
        render do
          html do |message|
            link_to(nuntius.resend_admin_message_path(message), title: 'Resend Message', data: { turbo_method: :post }, class: 'bg-gray-200 text-black p-1 w-6 items-center flex rounded dark:bg-gray-700 dark:text-white') do
              content_tag(:i, nil, class: 'fal fa-rotate-right')
            end
          end
        end
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
