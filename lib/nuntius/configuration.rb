# frozen_string_literal: true

module Nuntius
  module Options
    module ClassMethods
      def option(name, default: nil, proc: false)
        attr_writer(name)
        schema[name] = {default: default, proc: proc}

        if schema[name][:proc]
          define_method(name) do |*params|
            value = instance_variable_get(:"@#{name}")
            instance_exec(*params, &value)
          end
        else
          define_method(name) do
            instance_variable_get(:"@#{name}")
          end
        end
      end

      def schema
        @schema ||= {}
      end
    end

    def set_defaults!
      self.class.schema.each do |name, options|
        instance_variable_set(:"@#{name}", options[:default])
      end
    end

    def self.included(cls)
      cls.extend(ClassMethods)
    end
  end

  class Configuration
    include Options

    # The icons the admin shows (Font Awesome classes, by what they're for): Font Awesome Free's by default. An app
    # with Font Awesome Pro takes PRO_ICONS (config.icons = Nuntius::Configuration::PRO_ICONS), or merges its own in.
    # A list (templates) is its index page's icon, a record (template) its own page's and the dashboard menu's.
    FREE_ICONS = {
      templates: "fa-solid fa-file",
      template: "fa-solid fa-file",
      layouts: "fa-solid fa-table-columns",
      layout: "fa-solid fa-table-columns",
      locales: "fa-solid fa-language",
      locale: "fa-solid fa-language",
      campaigns: "fa-solid fa-bullhorn",
      campaign: "fa-solid fa-bullhorn",
      lists: "fa-solid fa-address-book",
      list: "fa-solid fa-address-book",
      subscriber: "fa-solid fa-address-card",
      subscribers_import: "fa-solid fa-file-import",
      messages: "fa-solid fa-envelope",
      message: "fa-solid fa-envelope",
      new: "fa-solid fa-plus",
      delete: "fa-solid fa-trash",
      resend: "fa-solid fa-rotate-right",
      schedule: "fa-solid fa-paper-plane",
      deschedule: "fa-solid fa-calendar-xmark",
      cancel: "fa-solid fa-ban",
      attachment: "fa-solid fa-paperclip",
      sent_at: "fa-solid fa-envelope",
      created_at: "fa-solid fa-calendar",
      transport_mail: "fa-solid fa-envelope",
      transport_sms: "fa-solid fa-comment-sms",
      transport_push: "fa-solid fa-bell",
      transport_voice: "fa-solid fa-phone",
      transport_slack: "fa-brands fa-slack",
      transport: "fa-solid fa-paper-plane"
    }.freeze

    PRO_ICONS = FREE_ICONS.merge(
      templates: "fad fa-file",
      template: "fal fa-file",
      layouts: "fad fa-table-layout",
      layout: "fal fa-table-layout",
      locales: "fad fa-language",
      locale: "fal fa-language",
      campaigns: "fad fa-megaphone",
      campaign: "fal fa-megaphone",
      lists: "fad fa-address-book",
      list: "fad fa-address-book",
      subscriber: "fad fa-address-card",
      subscribers_import: "fad fa-file-import",
      messages: "fad fa-envelope",
      message: "fad fa-envelope",
      new: "fal fa-plus",
      resend: "fal fa-rotate-right",
      sent_at: "fal fa-envelope",
      created_at: "fal fa-calendar"
    ).freeze

    option :logger, default: -> { Rails.logger }, proc: true
    # The concern the admin controllers include to authenticate, e.g. "AdminAuthenticated" (your app's own)
    option :admin_authentication_module, default: nil
    # Whether the current user may see the admin's tables, which Mensa serves outside the admin's controllers (at
    # its own mount), so admin_authentication_module doesn't guard them: their readable? answers it, for a host
    # that asks a table before serving it
    option :tables_readable, default: -> { true }, proc: true
    option :base_controller, default: "::ApplicationController"
    option :layout, default: "application"
    option :admin_layout, default: "application"
    option :icons, default: FREE_ICONS
    option :jobs_queue_name, default: "message"
    option :allow_custom_events, default: false
    # Whether a list's page has Nuntius' Import of subscribers from a CSV; false for an app with its own import
    option :subscribers_import, default: true
    # The hour from which templates about a date (a birthday) are sent on it
    option :timebased_send_hour, default: 9
    # At most this many messages a timebased template sends in a run; one that
    # would send more is held: disabled and reported (a template can set its own)
    option :timebased_limit, default: 500
    option :active_storage_service
    option :host, default: ->(message) {}, proc: true
    # The path to a message's or subscriber's object in the admin tables, when
    # it isn't a route of its engine or the app, as [:admin, object] or object
    option :object_path, default: ->(object) {}, proc: true

    # Every template, campaign, list, layout, locale and message belongs to an account.
    #
    #   account_class:     the model accounts are, its table gets the foreign keys
    #   current_account:   the account of the current request; new records get it, and the admin shows its records
    #   account_for:       the account a messenger sends for, for its object; a messenger can override it
    #                      (see BaseMessenger.account)
    #   can_create_global: whether the current account may make templates global: templates used for every
    #                      account, not only its own
    option :account_class, default: "Account"
    option :current_account, default: -> {}, proc: true
    option :account_for, default: lambda { |object|
      if object.is_a?(account_class.constantize)
        object
      elsif object.respond_to?(:account)
        object.account
      else
        current_account
      end
    }, proc: true
    option :can_create_global, default: -> { false }, proc: true

    # The records the admin shows, a scope on each model: by default the current account's
    attr_accessor :visible_scope
    attr_writer :default_params

    attr_reader :transports, :providers, :lettermint_webhook_settings

    def initialize
      set_defaults!

      @nuntiable_classes = []
      @nuntiable_class_names = []
      @transports = []
      @providers = {}
      @visible_scope = -> { owned_by(Nuntius.config.current_account) }
      @default_params = {}
    end

    def add_nuntiable_class(klass)
      @nuntiable_class_names = []
      @nuntiable_classes << klass.to_s unless @nuntiable_classes.include?(klass.to_s)
    end

    def nuntiable_class_names
      return @nuntiable_class_names if @nuntiable_class_names.present?

      load_nuntiable_classes
      compile_nuntiable_class_names!
    end

    def provider(provider, transport:, priority: 1, timeout: 0, settings: {})
      if @transports.include? transport
        @providers[transport.to_sym] ||= []
        @providers[transport.to_sym].push(provider: provider, priority: priority, timeout: timeout, settings: settings)
      else
        Nuntius.config.logger.call.warn "provider #{provider} not enabled as transport #{transport} is not enabled"
      end
    end

    def transport(transport)
      @transports.push(transport) if transport
    end

    # The transport new templates start with: mail, when it's enabled
    def default_transport
      (@transports.map(&:to_s).include?("mail") ? "mail" : @transports.first)&.to_s
    end

    # Receive message status updates from Lettermint through a webhook. Nuntius creates (or repairs) the webhook
    # with Lettermint on every server start.
    #
    #   api_token:     Lettermint Team API token, used to manage the webhook
    #   project_id:    Lettermint project to receive events for
    #   route_id:      optional, limit events to a single route of the project
    #   host:          public host Nuntius is reachable on (example: https://app.example.com), defaults to config.host
    #   setup_on_boot: check/create the webhook on server start (default: true)
    def lettermint_webhook(api_token:, project_id:, route_id: nil, host: nil, name: "Nuntius", setup_on_boot: true)
      @lettermint_webhook_settings = {
        api_token: api_token,
        project_id: project_id,
        route_id: route_id.presence,
        host: host,
        name: name,
        setup_on_boot: setup_on_boot
      }
    end

    def default_params(event, record)
      @default_params.is_a?(Proc) ? instance_exec(event, record, &@default_params) : @default_params
    end

    private

    def compile_nuntiable_class_names
      names = []
      names << "Custom" if allow_custom_events

      @nuntiable_classes.each do |klass_name|
        klass = klass_name.constantize
        names << klass.name
        names += klass.descendants.map(&:name)
      end

      names.sort!
    end

    # Models are nuntiable once their class is loaded: without eager loading
    # (development) load the app's models first, or the list has only the ones
    # used so far
    def load_nuntiable_classes
      return unless defined?(Rails) && Rails.application && !Rails.application.config.eager_load

      models = Rails.root.join("app/models")
      Rails.autoloaders.main.eager_load_dir(models.to_s) if models.exist?
    end

    def compile_nuntiable_class_names!
      @nuntiable_class_names = compile_nuntiable_class_names
    end
  end

  module Configurable
    attr_writer :config

    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    alias_method :setup, :configure

    def reset_config!
      @config = Configuration.new
    end
  end
end
