module Nuntius
  class Configuration
    attr_accessor :admin_authentication_module
    attr_accessor :base_controller
    attr_writer   :logger

    attr_reader :protocols
    attr_reader :providers

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::INFO
      @base_controller = '::ApplicationController'
      @protocols = []
      @providers = {}
    end

    # logger [Object].
    def logger
      @logger.is_a?(Proc) ? instance_exec(&@logger) : @logger
    end

    # admin_mount_point [String].
    def admin_mount_point
      @admin_mount_point ||= '/scribo'
    end

    def provider(provider, protocol:, priority: 1, timeout: nil, settings: {})
      if @protocols.include? protocol
        @providers[protocol.to_sym] ||= []
        @providers[protocol.to_sym].push(provider: provider, priority: priority, timeout: timeout, settings: settings)
      else
        Nuntius.logger.warn "provider #{provider} not enabled as protocol #{protocol} is not enabled"
      end
    end

    def protocol(protocol)
      @protocols.push(protocol) if protocol
    end
  end
end
