# frozen_string_literal: true

class NuntiusMessagesTable < ActionTable::ActionTable
  model Nuntius::Message

  column(:id) { |message| message.id.first(8) }
  column(:created_at) { |message| ln(message.created_at) }
  column(:transport)
  column(:provider)
  column(:origin) do |message|
    link_to message.campaign&.name, nuntius.edit_admin_campaign_path(message.campaign) if message.campaign
    link_to message.template&.description, nuntius.edit_admin_template_path(message.template) if message.template
  end
  column(:subject) do |message|
    if message.nuntiable
      link_to "#{message.nuntiable_type} [#{message.nuntiable}]", begin
        url_for(message.nuntiable)
      rescue StandardError
        '#'
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
