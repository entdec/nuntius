# frozen_string_literal: true

class NuntiusListsTable < ActionTable::ActionTable
  model Nuntius::List

  column(:name)
  column(:metadata) { |list| Nuntius.config.metadata_humanize(list.metadata) }
  column(:subscribers, sort_field: 'subscribers_count') { |list| list.subscribers.count || '-' }

  initial_order :name, :asc

  row_link { |list| nuntius.edit_admin_list_path(list) }

  private

  def scope
    @scope = Nuntius::List.visible
  end
end
