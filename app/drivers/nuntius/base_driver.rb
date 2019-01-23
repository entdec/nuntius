# frozen_string_literal: true

module Nuntius
  class BaseDriver
    def initialize(message = nil)
      @message = message
    end

    def self.all_settings
      @all_settings ||= []
    end

    def self.setting_reader(name, required: false, description: '')
      @all_settings ||= []
      @all_settings.push(name: name, required: required, description: description)
      define_method(name) { settings[name] }
    end

    def self.adapter(adapter=nil)
      @adapter = adapter if adapter
      @adapter
    end

    def self.states(mapping=nil)
      @states = mapping if mapping
      @states
    end

    def send
      # Not implemented
    end

    def name
      self.class.name.demodulize.underscore.gsub(/_driver$/, '').to_sym
    end

    private

    def translated_status(status)
      states.find { |key| key.is_a?(Array) ? key.include?(status) : key == status }&.last || 'sending'
    end

    def settings
      Nuntius.config.drivers[self.class.adapter].to_a.find { |d| d[:driver] == name }[:settings]
    end
  end
end
