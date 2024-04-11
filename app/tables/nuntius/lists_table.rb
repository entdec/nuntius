# frozen_string_literal: true

module Nuntius
  class ListsTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::List

      column(:name)
      column(:metadata) do
        render do
          html do |template|
            Nuntius.config.metadata_humanize(template.metadata)
          end
        end
      end
      column(:subscribers_count) do
        attribute "subscribers_count"
      end

      order name: :asc

      link { |list| nuntius.edit_admin_list_path(list) }
    end

    private

    def scope
      @scope = Nuntius::List.visible
    end
  end
end
