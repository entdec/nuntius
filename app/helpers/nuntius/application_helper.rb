# frozen_string_literal: true

module Nuntius
  module ApplicationHelper
    # The enabled transports by their names for people, alphabetically
    def nuntius_transport_options
      Nuntius.config.transports
        .map { |transport| [t(transport, scope: "nuntius.transports", default: transport.to_s.humanize), transport.to_s] }
        .sort_by { |label, _| label.downcase }
    end

    # A template's or campaign's conditions (see Conditions) as rules, with
    # its Liquid variables to choose from (EntDec::Conditions::Component)
    def nuntius_conditions(form)
      record = form.object
      roots = record.variable_roots
      conditions = Nuntius::Conditions.new(record.conditions)
      render EntDec::Conditions::Component.new(name: "#{form.object_name}[conditions]", match: conditions.match,
        rules: conditions.rules, variables_url: Nuntius::Variables.url(self, roots), describe: Nuntius::Variables.describer(roots))
    end

    # A field that takes Liquid, with the record's variables suggested while
    # typing {{ and a { } button to browse them (EntDec::LiquidField::Component)
    #
    #   = nuntius_liquid_field f do
    #     = f.input :to
    def nuntius_liquid_field(form, &)
      entdec_liquid_field(url: Nuntius::Variables.url(self, form.object.variable_roots), &)
    end

    # Data attributes for an element whose variable pickers and Liquid fields
    # follow the class chosen in a template's form (the nuntius--variables
    # controller): the variables URL of each of the classes
    def nuntius_variables_data(form, classes)
      urls = classes.to_h { |klass| [klass, Nuntius::Variables.url(self, form.object.variable_roots(klass))] }.compact
      {"data-nuntius--variables-urls-value" => urls.to_json, "data-nuntius--variables-for-value" => "#{form.object_name}[klass]"}
    end

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
      Satis::Menus::Builder.build([:nuntius, :templates]) do |m|
        m.item :new, link: nuntius.new_admin_template_path
      end
    end

    def nuntius_layouts_menu
      Satis::Menus::Builder.build([:nuntius, :layouts]) do |m|
        m.item :new, link: nuntius.new_admin_layout_path
      end
    end

    def nuntius_locales_menu
      Satis::Menus::Builder.build([:nuntius, :locales]) do |m|
        m.item :new, link: nuntius.new_admin_locale_path
      end
    end

    def nuntius_campaigns_menu
      Satis::Menus::Builder.build([:nuntius, :campaigns]) do |m|
        m.item :new, link: nuntius.new_admin_campaign_path
        m.item :lists, link: nuntius.admin_lists_path
      end
    end

    def nuntius_lists_menu
      Satis::Menus::Builder.build([:nuntius, :lists]) do |m|
        m.item :new, link: nuntius.new_admin_list_path
      end
    end

    def nuntius_list_menu
      Satis::Menus::Builder.build([:nuntius, :lists]) do |m|
        m.item :new_subscriber, link: nuntius.new_admin_list_subscriber_path(@list) if @list.persisted?
        m.item :import_subscribers, link: nuntius.import_admin_list_subscribers_path(@list) if @list.persisted?
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

    # A message's HTML for the browser: its embedded images (cid:) come from storage
    def message_html(message)
      images = message.attachments.select(&:inline).index_by(&:content_id)
      html = message.html.to_s.gsub(/cid:([^"'\s)]+)/) do |reference|
        image = images[Regexp.last_match(1)]
        image ? main_app.rails_blob_path(image, disposition: "inline") : reference
      end
      html.html_safe
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
