# frozen_string_literal: true

module Nuntius
  class Configuration
    attr_accessor :admin_authentication_module, :base_controller, :base_runner, :layout, :admin_layout, :jobs_queue_name, :visible_scope, :add_metadata, :metadata_fields, :default_template_scope, :allow_custom_events, :active_storage_service
    attr_writer :logger, :host, :metadata_humanize, :default_params, :flow_color

    attr_reader :transports, :providers

    def initialize
      @logger = Logger.new($stdout)
      @logger.level = Logger::INFO
      @base_controller = "::ApplicationController"
      @base_runner = "Nuntius::BasicApplicationRunner"
      @nuntiable_classes = []
      @nuntiable_class_names = []
      @transports = []
      @providers = {}
      @jobs_queue_name = :message
      @visible_scope = -> { all }
      @add_metadata = -> {}
      @metadata_fields = {}
      @metadata_humanize = ->(data) { data.inspect }
      @default_template_scope = ->(_object) { all }
      @allow_custom_events = false
      @layout = "application"
      @admin_layout = "application"
      @active_storage_service = nil
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    def host(message)
      @host.is_a?(Proc) ? instance_exec(message, &@host) : @host
    end

    # Make the part that is important for visible readable for humans
    def metadata_humanize(metadata)
      @metadata_humanize.is_a?(Proc) ? instance_exec(metadata, &@metadata_humanize) : @metadata_humanize
    end

    # admin_mount_point [String].
    def admin_mount_point
      @admin_mount_point ||= "/nuntius"
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
        Nuntius.logger.warn "provider #{provider} not enabled as transport #{transport} is not enabled"
      end
    end

    def transport(transport)
      @transports.push(transport) if transport
    end

    def default_params(transaction_log_entry)
      @default_params.is_a?(Proc) ? instance_exec(transaction_log_entry, &@default_params) : @default_params
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
end
