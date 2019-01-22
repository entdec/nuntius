# frozen_string_literal: true

module Nuntius
  class BaseDriver

    def initialize(settings)
      @settings = settings
    end

    def self.all_settings
      @all_settings
    end

    def self.setting_reader(name, required: false, description: '')
      @all_settings ||= []

      @all_settings.push(name: name, required: required, description: description)
      define_method(name) { instance_variable_get('@settings')[name] }
    end

    def self.adapter(adapter)
      @adapter = adapter if adapter
      @adapter
    end

    def send
      # Not implemented
    end
  end
end
