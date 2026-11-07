# frozen_string_literal: true

module Nuntius
  class LocalesTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Locale

      column(:key)
      order key: :asc

      link { |locale| nuntius.edit_admin_locale_path(locale) }
    end

    private

    def scope
      @scope = Nuntius::Locale.visible
    end
  end
end
