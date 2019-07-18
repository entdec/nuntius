module Nuntius
  class Configuration
    attr_accessor :admin_authentication_module
    attr_accessor :base_controller
    attr_writer   :logger

    attr_reader :transports
    attr_reader :providers
    attr_accessor :nuntiable_class_names
    attr_accessor :jobs_queue_name

    attr_accessor :visible_scope
    attr_accessor :add_metadata

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
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
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
