# frozen_string_literal: true

module Nuntius
  class LayoutsTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Layout

      column(:name)
      column(:metadata) do
        render do
          html do |template|
            Nuntius.config.metadata_humanize(template.metadata)
          end
        end
      end

      action :delete do
        link { |layout| nuntius.admin_layout_url(layout) }
        icon "fa fa-trash"
        link_attributes data: {"turbo-confirm": "Are you sure you want to delete the layout?", "turbo-method": :delete}
      end

      order name: :asc

      link { |layout| nuntius.edit_admin_layout_path(layout) }
    end

    private

    def scope
      @scope = Nuntius::Layout.visible
    end
  end
end
