# frozen_string_literal: true

module ApplicationHelper
  def ln(datetime = Time.now, time_zone: Time.zone, format: :long, blank_text: "", as: :datetime)
    if datetime.blank?
      blank_text
    else
      to_format = datetime.in_time_zone(time_zone)
      to_format = to_format.to_date if as == :date
      content_tag(:time, I18n.l(to_format, format: format), :datetime => datetime&.iso8601, "data-tooltip-content" => I18n.l(to_format))
    end
  end

  def sidebar_menu
    Satis::Menus::Builder.build(:sidebar) do |m|
      m.item :dashboard, label: "Dashboard", icon: "fa fa-house", link: nuntius.root_path
      m.item :messages, label: "Messages", icon: "fa fa-envelope", link: nuntius.admin_messages_path
      m.item :templates, label: "Templates", icon: "fa fa-file", link: nuntius.admin_templates_path
      m.item :layouts, label: "Layouts", icon: "fa fa-table-columns", link: nuntius.admin_layouts_path
      m.item :campaigns, label: "Campaigns", icon: "fa fa-bullhorn", link: nuntius.admin_campaigns_path
      m.item :lists, label: "Lists", icon: "fa fa-list", link: nuntius.admin_lists_path
      m.item :locales, label: "Locales", icon: "fa fa-language", link: nuntius.admin_locales_path
    end
  end
end
