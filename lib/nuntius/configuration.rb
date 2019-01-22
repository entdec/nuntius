module Nuntius
  class Configuration
    attr_accessor :admin_authentication_module
    attr_accessor :base_controller
    attr_writer   :logger

    attr_reader :adapters
    attr_reader :drivers

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @base_controller = '::ApplicationController'
      @adapters = []
      @drivers = {}
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    # admin_mount_point [String].
    def admin_mount_point
      @admin_mount_point ||= '/scribo'
    end

    def driver(driver, adapter:, priority: 1, timeout: nil, settings: {})
      if @adapters.include? adapter
        @drivers[adapter.to_sym] ||= []
        @drivers[adapter.to_sym].push(driver: driver, priority: priority, timeout: timeout, settings: settings)
      else
        Nuntius.logger.warn "Driver #{driver} not enabled as adapter #{adapter} is not enabled"
      end
    end

    def adapter(adapter)
      @adapters.push(adapter) if adapter
    end
  end
end
