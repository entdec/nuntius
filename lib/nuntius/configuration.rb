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

    option :logger, default: -> { Rails.logger }, proc: true
    option :admin_authentication_module, default: "Auxilium::Concerns::AdminAuthenticated"
    option :base_controller, default: "::ApplicationController"
    option :layout, default: "application"
    option :admin_layout, default: "application"
    option :jobs_queue_name, default: "message"
    option :allow_custom_events, default: false
    # The hour from which templates about a date (a birthday) are sent on it
    option :timebased_send_hour, default: 9
    option :active_storage_service
    option :host, default: ->(message) {}, proc: true

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
