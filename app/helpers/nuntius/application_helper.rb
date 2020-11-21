# frozen_string_literal: true

module Nuntius
  module ApplicationHelper
    def dashboard_context_menu
      @dashboard_context_menu ||= Electio::Menu.new(context: self) do |menu|
        menu.item :layouts, link: admin_layouts_path
        menu.item :locales, link: admin_locales_path
        menu.item :templates, link: admin_templates_path
        menu.item :campaigns, link: admin_campaigns_path
      end
      @dashboard_context_menu.for_context
    end

    def templates_context_menu
      @templates_context_menu ||= Electio::Menu.new(context: self) do |menu|
        menu.item :new, link: new_admin_template_path
      end
      @templates_context_menu.for_context
    end

    def messages_context_menu
      @messages_context_menu ||= Electio::Menu.new(context: self) do |menu|
        menu.item :new, link: new_admin_message_path
      end
      @messages_context_menu.for_context
    end

    def layouts_context_menu
      @layouts_context_menu ||= Electio::Menu.new(context: self) do |menu|
        menu.item :new, link: new_admin_layout_path
      end
      @layouts_context_menu.for_context
    end

    def locales_context_menu
      @locales_context_menu ||= Electio::Menu.new(context: self) do |menu|
        menu.item :new, link: new_admin_locale_path
      end
      @locales_context_menu.for_context
    end

    def campaigns_context_menu
      @campaigns_context_menu ||= Electio::Menu.new(context: self) do |menu|
        menu.item :new, link: new_admin_campaign_path
        menu.item :lists, link: admin_lists_path
      end
      @campaigns_context_menu.for_context
    end

    def lists_context_menu
      @lists_context_menu ||= Electio::Menu.new(context: self) do |menu|
        menu.item :new, link: new_admin_list_path
      end
      @lists_context_menu.for_context
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
