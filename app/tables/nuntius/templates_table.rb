# frozen_string_literal: true

module Nuntius
  class TemplatesTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Template

      column(:description)
      column(:enabled)
      column(:klass)
      column(:event)
      column(:messages_count) do
        attribute "(select count(id) from nuntius_messages where nuntius_messages.template_id = nuntius_templates.id)"
        render do
          html do |template|
            link_to(template.messages_count, nuntius.admin_messages_path(template_id: template.id))
          end
        end
      end

      column(:global)

      action :delete do
        link { |template| nuntius.admin_template_path(template) }
        icon "fa-solid fa-trash"
        link_attributes data: {"turbo-confirm": "Are you sure you want to delete the template?", "turbo-method": :delete}
      end

      order description: :asc

      link { |template| nuntius.edit_admin_template_path(template) }
    end

    private

    def scope
      @scope = Nuntius::Template.visible
      # @scope = Nuntius::Template.visible.select("nuntius_templates.*, (select count(id) from nuntius_messages where nuntius_messages.template_id = nuntius_templates.id) as message_count")
    end
  end
end
