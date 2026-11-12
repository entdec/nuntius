# frozen_string_literal: true

module Nuntius
  class TemplatesTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::Template

      column(:description)
      column(:enabled)
      column(:transport) do
        render do
          html { |template| t(template.transport, scope: "nuntius.transports", default: template.transport.to_s.humanize) }
        end
      end
      # Its layout, or the old layout it has until it's converted
      column(:layout_name) do
        attribute "coalesce((select name from nuntius_layouts where nuntius_layouts.id = nuntius_templates.layout_id), (select name from nuntius_old_layouts where nuntius_old_layouts.id = nuntius_templates.old_layout_id))"
      end
      column(:klass) do
        render do
          html { |template| template.klass_label }
        end
      end
      column(:event) do
        render do
          html { |template| template.event_label }
        end
      end
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

      view :default do
        name -> { I18n.t("nuntius.tables.templates.views.enabled") }
        filter :enabled do
          operator :is
          value true
        end
      end
      view :disabled do
        name -> { I18n.t("nuntius.tables.templates.views.disabled") }
        filter :enabled do
          operator :is
          value false
        end
      end

      link { |template| nuntius.edit_admin_template_path(template) }
    end

    private

    def scope
      @scope = Nuntius::Template.visible
      @scope = @scope.where(transport: params[:transport]) if params[:transport].present?
      @scope = @scope.where(layout_id: params[:layout_id]) if params[:layout_id].present?
      @scope
      # @scope = Nuntius::Template.visible.select("nuntius_templates.*, (select count(id) from nuntius_messages where nuntius_messages.template_id = nuntius_templates.id) as message_count")
    end
  end
end
