# frozen_string_literal: true

class NuntiusTemplatesTable < ActionTable::ActionTable
  model Nuntius::Template

  column(:description)
  column(:enabled, as: :boolean)
  column(:klass)
  column(:event)
  column(:messages, sort_field: 'message_count') { |template| link_to template.messages.count, nuntius.admin_messages_path(template_id: template.id) }

  column(:metadata) { |template| Nuntius.config.metadata_humanize(template.metadata) }
  column(:created_at) { |flow| ln(flow.created_at) }

  column :actions, title: '', sortable: false do |template|
    content_tag(:span, class: 'btn-group btn-group-xs') do
      concat link_to(content_tag(:i, nil, class: 'fa fa-trash'), nuntius.admin_template_path(template), data: { turbo_confirm: 'Are you sure you want to delete the template?', turbo_method: :delete }, class: 'btn btn-xs btn-danger')
    end
  end

  initial_order :description, :asc

  row_link { |template| nuntius.edit_admin_template_path(template) }

  private

  def scope
    @scope = Nuntius::Template.visible
    @scope = Nuntius::Template.visible.select('nuntius_templates.*, (select count(id) from nuntius_messages where nuntius_messages.template_id = nuntius_templates.id) as message_count')
  end
end
