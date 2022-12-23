# frozen_string_literal: true

class NuntiusLocalesTable < ActionTable::ActionTable
  model Nuntius::Locale

  column(:key)
  column(:metadata) { |locale| Nuntius.config.metadata_humanize(locale.metadata) }

  table_views(to_s.underscore)

  initial_order :mkey, :asc

  row_link { |locale| nuntius.edit_admin_locale_path(locale) }

  private

  def scope
    @scope = Nuntius::Locale.visible
  end
end
