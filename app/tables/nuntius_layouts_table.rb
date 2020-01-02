# frozen_string_literal: true

class NuntiusLayoutsTable < ActionTable::ActionTable
  model Nuntius::Layout

  column(:name) { |layout| layout.name }
  column(:metadata) { |layout| Nuntius.config.metadata_humanize(layout.metadata) }

  initial_order :name, :asc

  row_link { |layout| nuntius.edit_admin_layout_path(layout) }

  private

  def scope
    @scope = Nuntius::Layout.visible
  end

  def filtered_scope
    @filtered_scope = scope

    @filtered_scope
  end
end
