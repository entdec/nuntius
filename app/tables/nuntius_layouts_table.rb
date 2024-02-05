# frozen_string_literal: true

class NuntiusLayoutsTable < ActionTable::ActionTable
  model Nuntius::Layout

  column(:name)
  column(:metadata) { |layout| Nuntius.config.metadata_humanize(layout.metadata) }

  column :actions, title: '', sortable: false do |layout|
    content_tag(:span, class: 'btn-group btn-group-xs') do
      concat link_to(content_tag(:i, nil, class: 'fa fa-trash'), nuntius.admin_layout_url(layout), data: { turbo_confirm: 'Are you sure you want to delete the layout?', turbo_method: :delete }, class: 'btn btn-xs btn-danger')
    end
  end

  initial_order :name, :asc

  row_link { |layout| nuntius.edit_admin_layout_path(layout) }

  private

  def scope
    @scope = Nuntius::Layout.visible
  end
end
