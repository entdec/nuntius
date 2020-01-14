# frozen_string_literal: true

class NuntiusTemplatesTable < ActionTable::ActionTable
  model Nuntius::Template

  column(:description)
  column(:metadata) { |template| Nuntius.config.metadata_humanize(template.metadata) }
  column(:enabled) { |template| content_tag(:i, nil, class: template.enabled ? 'fa fa-check' : 'fa-times') }
  column(:klass)
  column(:event)
  column(:"# messages") { |template| link_to template.messages.count, nuntius.admin_messages_path(template_id: template.id) }

  column :actions, title: '', sortable: false do |template|
    content_tag(:span, class: 'btn-group btn-group-xs') do
      concat link_to(content_tag(:i, nil, class: 'fa fa-trash'), nuntius.admin_template_path(template), data: { confirm: 'Are you sure you want to delete the template?', method: :delete }, class: 'btn btn-xs btn-danger')
    end
  end

  initial_order :description, :asc

  row_link { |template| nuntius.edit_admin_template_path(template) }

  private

  def scope
    @scope = Nuntius::Template.visible
  end

  def filtered_scope
    @filtered_scope = scope

    @filtered_scope
  end
end