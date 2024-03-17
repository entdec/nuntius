# frozen_string_literal: true

class NuntiusMessagesTable < ActionTable::ActionTable
  model Nuntius::Message

  column(:to)
  column(:created_at, html_value: proc { |message| ln(message.created_at) })
  column(:last_sent_at, html_value: proc { |message| ln(message.last_sent_at) })
  column(:origin, sort_field: "nuntius_messages.campaign_id, nuntius_messages.template_id") do |message|
    link_to message.campaign&.name, nuntius.edit_admin_campaign_path(message.campaign) if message.campaign
    link_to message.template&.description, nuntius.edit_admin_template_path(message.template) if message.template
  end
  column(:subject) do |message|
    if message.nuntiable
      link_to "#{message.nuntiable_type} [#{message.nuntiable}]", begin
        url_for(message.nuntiable)
      rescue
        "#"
      end
    end
  end
  column(:status)

  initial_order :created_at, :desc

  row_link { |message| nuntius.admin_message_path(message) }

  private

  def scope
    @scope = Nuntius::Message.visible
    @scope = @scope.where(nuntiable_id: params[:nuntiable_id], nuntiable_type: params[:nuntiable_type]) if params[:nuntiable_id]
    @scope = @scope.where(template_id: params[:template_id]) if params[:template_id]
    @scope
  end
end
