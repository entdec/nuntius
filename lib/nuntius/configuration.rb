# frozen_string_literal: true

module Nuntius
  class Configuration
    attr_accessor :admin_authentication_module
    attr_accessor :base_controller
    attr_writer   :logger
    attr_writer   :host
    attr_writer   :metadata_humanize

    attr_reader :transports
    attr_reader :providers
    attr_accessor :nuntiable_class_names
    attr_accessor :jobs_queue_name

    attr_accessor :visible_scope
    attr_accessor :add_metadata
    attr_accessor :metadata_fields

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @base_controller = '::ApplicationController'
      @nuntiable_class_names = []
      @transports = []
      @providers = {}
      @jobs_queue_name = :message
      @visible_scope = -> { all }
      @add_metadata = -> {}
      @metadata_fields = {}
      @metadata_humanize = ->(data) { data.inspect }
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
      @admin_mount_point ||= '/nuntius'
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
  end
end
