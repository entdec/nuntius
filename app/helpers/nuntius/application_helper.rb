# frozen_string_literal: true

module Nuntius
  module ApplicationHelper
    # The email editor's images (Admin::MediaController) and the URL its
    # preview compiles with them shown: a saved record's, or a new one's,
    # which uploads before it is saved, in the layout it starts from
    def nuntius_media_urls(record)
      key = {Nuntius::Layout => "layout", Nuntius::Template => "template", Nuntius::Campaign => "campaign"}.fetch(record.class)
      if record.persisted?
        {media_url: public_send(:"media_admin_#{key}_path", record), compile_url: public_send(:"media_compile_admin_#{key}_path", record)}
      else
        query = {layout_id: record.try(:layout_id)}.compact
        {media_url: public_send(:"media_admin_#{key.pluralize}_path", query), compile_url: public_send(:"media_compile_admin_#{key.pluralize}_path", query)}
      end
    end

    # The enabled transports by their names for people, alphabetically
    def nuntius_transport_options
      Nuntius.config.transports
        .map { |transport| [t(transport, scope: "nuntius.transports", default: transport.to_s.humanize), transport.to_s] }
        .sort_by { |label, _| label.downcase }
    end

    # The enabled transports, the common ones first
    def nuntius_transports
      order = %w[mail sms push teams slack voice]
      Nuntius.config.transports.map(&:to_s).uniq.sort_by { |transport| [order.index(transport) || order.size, transport] }
    end

    # A transport's name for people
    def nuntius_transport_name(transport)
      t(transport, scope: "nuntius.transports", default: transport.to_s.humanize)
    end

    # An icon's Font Awesome classes, by what it's for (see config.icons)
    def nuntius_icon(name)
      Nuntius.config.icons.fetch(name)
    end

    # A transport's icon: Font Awesome's, or the product's logo for Teams
    # (Font Awesome has none for it)
    def nuntius_transport_icon(transport, css_class = "")
      case transport.to_s
      when "teams"
        render "nuntius/admin/shared/teams_logo", css_class: css_class
      else
        icon = Nuntius.config.icons[:"transport_#{transport}"] || nuntius_icon(:transport)
        tag.i(class: [icon, css_class], "aria-hidden": true)
      end
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

    # The form's builder as Rails' own, for what draws its fields itself inline: the trigger's sentence
    # (entdec_pill_select), a title edited in place, and the editors inside a Liquid field (entdec_code_editor);
    # FormComponents' builder would put a label and description around each
    def nuntius_plain_form(form)
      ActionView::Helpers::FormBuilder.new(form.object_name, form.object, self, form.options)
    end

    # An admin page in its frame (shared/_page, which the host app may draw its own way): its title, actions and,
    # for a form (form:), its Save, over the tabs its block adds (page.tab) or else what the block gives, with what
    # it puts beside them (page.aside)
    #
    #   <%= nuntius_page :nuntius_admin_locales, title: t(".title"), icon: nuntius_icon(:locale), form: f do |page| %>
    #     <%= f.text_field :key %>
    #   <% end %>
    def nuntius_page(name, title:, icon: nil, form: nil, actions: [], back: nil, &block)
      page = Nuntius::Page.new(self)
      body = capture(page, &block)
      render "nuntius/admin/shared/page", name: name, title: title, icon: icon, form: form, actions: actions, back: back, tabs: page.tabs, aside: page.aside, body: body
    end

    # One of a record's details, labelled by its page's info_item.main.<key> (else the message's attribute's name),
    # in a list of them (dl.nuntius-info); wide: across it, the block for what to show instead of value
    def nuntius_info_item(key, value = nil, wide: false, icon: nil, &block)
      label = safe_join([(tag.i(class: icon) if icon), t(".info_item.main.#{key}", default: Nuntius::Message.human_attribute_name(key))].compact, " ")
      tag.div(class: ["nuntius-info__item", ("nuntius-info__item--wide" if wide)]) do
        tag.dt(label, class: "nuntius-info__label") + tag.dd(block ? capture(&block) : value, class: "nuntius-info__value")
      end
    end

    # The index pages' actions, for their frame (shared/_index) to show as it shows actions
    def nuntius_templates_actions
      [nuntius_action(:new, :templates, nuntius.new_admin_template_path)]
    end

    def nuntius_layouts_actions
      [nuntius_action(:new, :layouts, nuntius.new_admin_layout_path)]
    end

    def nuntius_locales_actions
      [nuntius_action(:new, :locales, nuntius.new_admin_locale_path)]
    end

    def nuntius_campaigns_actions
      [nuntius_action(:new, :campaigns, nuntius.new_admin_campaign_path), nuntius_action(:lists, :campaigns, nuntius.admin_lists_path, icon: nuntius_icon(:lists))]
    end

    def nuntius_lists_actions
      [nuntius_action(:new, :lists, nuntius.new_admin_list_path)]
    end

    # A saved list's: adding its subscribers
    def nuntius_list_actions(list)
      return [] unless list.persisted?

      [nuntius_action(:new_subscriber, :lists, nuntius.new_admin_list_subscriber_path(list), icon: nuntius_icon(:subscriber)),
        (nuntius_action(:import_subscribers, :lists, nuntius.import_admin_list_subscribers_path(list), icon: nuntius_icon(:subscribers_import)) if Nuntius.config.subscribers_import)].compact
    end

    # An action labelled menu.nuntius.<page>.<id>, New's with its icon
    def nuntius_action(id, page, link, icon: (nuntius_icon(:new) if id == :new), **options)
      Nuntius::PageAction.new(id: id, label: t("menu.nuntius.#{page}.#{id}"), link: link, icon: icon, **options)
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
