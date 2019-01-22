# frozen_string_literal: true

module Nuntius
  class BaseDriver

    def initialize(message = nil)
      @message = message
    end

    def self.all_settings
      @all_settings
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

    def send
      # Not implemented
    end

    def name
      self.class.name.demodulize.underscore.gsub(/_driver$/, '').to_sym
    end

    def settings
      Nuntius.config.drivers[self.class.adapter].to_a.find { |d| d[:driver] == name }[:settings]
    end
  end
end
