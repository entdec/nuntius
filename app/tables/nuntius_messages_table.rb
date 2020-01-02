# frozen_string_literal: true

class NuntiusMessagesTable < ActionTable::ActionTable
  model Nuntius::Message

  column(:id) { |message| message.id.first(8) }
  column(:created_at) { |message| ln(message.created_at) }
  column(:transport)
  column(:provider)
  column(:origin) do |message|
    if message.campaign
      link_to message.campaign&.name, nuntius.edit_admin_campaign_path(message.campaign)
    end
    if message.template
      link_to message.template&.description, nuntius.edit_admin_template_path(message.template)
    end
  end
  column(:subject) { |message| link_to "#{message.nuntiable_type} [#{message.nuntiable}]", (url_for(message.nuntiable) rescue '#') if message.nuntiable }
  column(:status)

  initial_order :created_at, :desc

  row_link { |message| nuntius.admin_message_path(message) }

  private

  def scope
    @scope = Nuntius::Message.visible
  end

  def filtered_scope
    @filtered_scope = scope

    if params[:template_id]
      @filtered_scope = @filtered_scope.where(template_id: params[:template_id])
    end

    @filtered_scope
  end
end
