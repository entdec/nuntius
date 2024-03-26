# frozen_string_literal: true

module Nuntius
  module ApplicationHelper
    def nuntius_dashboard_menu
      Satis::Menus::Builder.build(:dashboard) do |m|
        m.item :messages, link: nuntius.admin_messages_path, icon: "fal fa-envelope"
        m.item :templates, link: nuntius.admin_templates_path, icon: "fal fa-file"
        m.item :layouts, link: nuntius.admin_layouts_path, icon: "fal fa-table-layout"
        m.item :locales, link: nuntius.admin_locales_path, icon: "fal fa-language"
        m.item :campaigns, link: nuntius.admin_campaigns_path, icon: "fal fa-megaphone"
        m.item :lists, link: nuntius.admin_lists_path, icon: "fal fa-address-book"
      end
    end

    def nuntius_templates_menu
      Satis::Menus::Builder.build(:templates) do |m|
        m.item :new, link: nuntius.new_admin_template_path
      end
    end

    def nuntius_layouts_menu
      Satis::Menus::Builder.build(:layouts) do |m|
        m.item :new, link: nuntius.new_admin_layout_path
      end
    end

    def nuntius_locales_menu
      Satis::Menus::Builder.build(:locales) do |m|
        m.item :new, link: nuntius.new_admin_locale_path
      end
    end

    def nuntius_campaigns_menu
      Satis::Menus::Builder.build(:campaign) do |m|
        m.item :new, link: nuntius.new_admin_campaign_path
      end
    end

    def nuntius_lists_menu
      Satis::Menus::Builder.build(:lists) do |m|
        m.item :new, link: nuntius.new_admin_list_path
      end
    end

    def nuntius_list_menu
      Satis::Menus::Builder.build(:lists) do |m|
        m.item :new_subscriber, link: nuntius.new_admin_list_subscriber_path(@list) if @list.persisted?
      end
    end

    def present(model, presenter_class = nil)
      array = nil
      if model.is_a? Array
        array = model
        model = model.first
      end

      klass = presenter_class || "#{model.class}Presenter".constantize
      presenter = array ? array.map { |m| klass.new(m) } : klass.new(model)
      yield(presenter) if block_given?
    end

    def method_missing(method, *args, &block)
      if main_app.respond_to?(method)
        main_app.send(method, *args)
      else
        super
      end
    end
  end
end
