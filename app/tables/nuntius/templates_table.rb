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

      # Enabled ones, as a filter that can be taken off
      partial :enabled do
        filter :enabled do
          operator :is
          value true
        end
      end
      view :default do
        name -> { I18n.t("nuntius.tables.templates.views.all") }
        include :enabled
      end
      # The templates of each transport made from the new template's cards
      %w[mail sms push voice].each do |transport|
        view transport.to_sym do
          name -> { I18n.t(transport, scope: "nuntius.transports") }
          include :enabled

          filter :transport do
            operator :is
            value transport
          end
        end
      end

      link { |template| nuntius.edit_admin_template_path(template) }
    end

    private

    def scope
      @scope = Nuntius::Template.visible
      @scope = @scope.where(layout_id: params[:layout_id]) if params[:layout_id].present?
      @scope
      # @scope = Nuntius::Template.visible.select("nuntius_templates.*, (select count(id) from nuntius_messages where nuntius_messages.template_id = nuntius_templates.id) as message_count")
    end
  end
end
