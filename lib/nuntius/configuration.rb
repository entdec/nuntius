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
    option :base_runner, default: "Nuntius::BasicApplicationRunner"
    option :layout, default: "application"
    option :admin_layout, default: "application"
    option :jobs_queue_name, default: "message"
    option :allow_custom_events, default: false
    option :active_storage_service
    option :host, default: ->(message) {}, proc: true

    attr_accessor :visible_scope, :add_metadata, :metadata_fields, :default_template_scope
    attr_writer :metadata_humanize, :default_params, :flow_color

    attr_reader :transports, :providers

    def initialize
      set_defaults!

      @nuntiable_classes = []
      @nuntiable_class_names = []
      @transports = []
      @providers = {}
      @visible_scope = -> { all }
      @add_metadata = -> {}
      @metadata_fields = {}
      @metadata_humanize = ->(data) { data.inspect }
      @default_template_scope = ->(_object) { all }
      @default_params = {}
    end

    # Make the part that is important for visible readable for humans
    def metadata_humanize(metadata)
      @metadata_humanize.is_a?(Proc) ? instance_exec(metadata, &@metadata_humanize) : @metadata_humanize
    end

    def add_nuntiable_class(klass)
      @nuntiable_class_names = []
      @nuntiable_classes << klass.to_s unless @nuntiable_classes.include?(klass.to_s)
    end

    def nuntiable_class_names
      return @nuntiable_class_names if @nuntiable_class_names.present?

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

    def default_params(event, record)
      @default_params.is_a?(Proc) ? instance_exec(event, record, &@default_params) : @default_params
    end

    def flow_color(template_id)
      @flow_color.is_a?(Proc) ? instance_exec(template_id, &@flow_color) : @flow_color
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
