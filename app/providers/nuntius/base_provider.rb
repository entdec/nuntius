# frozen_string_literal: true

module Nuntius
  class BaseProvider
    attr_reader :message

    def initialize(message = nil)
      @message = message
    end

    class << self
      def all_settings
        @all_settings ||= []
      end

      def setting_reader(name, required: false, default: nil, description: '')
        @all_settings ||= []
        @all_settings.push(name: name, required: required, default: default, description: description)
        define_method(name) { required ? settings.fetch(name) : settings.dig(name) || default }
      end

      def transport(transport = nil)
        @transport = transport if transport
        @transport
      end

      def states(mapping = nil)
        @states = mapping if mapping
        @states
      end

      def class_from_name(name, transport)
        Nuntius.const_get("#{name}_#{transport}_provider".camelize)
      rescue StandardError
        nil
      end
    end

    # Override this in implementations
    def deliver
      @message
    end

    # Override this in implementations
    def refresh
      @message
    end

    # Override this in implementation
    def callback(_params)
      [404, { 'Content-Type' => 'text/html; charset=utf-8' }, ['Not found']]
    end

    def name
      self.class.name.demodulize.underscore.gsub(/_#{self.class.transport}_provider$/, '').to_sym
    end

    private

    def translated_status(status)
      self.class.states.find { |key, _value| key.is_a?(Array) ? key.include?(status) : key == status }&.last || 'sent'
    end

    def settings
      return @settings if @settings

      @settings = Nuntius.config.providers[self.class.transport].to_a.find { |d| d[:provider] == name }[:settings]
      @settings = instance_exec(@message, &@settings) if @settings.is_a?(Proc)
      @settings
    end
  end
end
