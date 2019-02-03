# frozen_string_literal: true

require 'liquor'

require 'nuntius/engine'
require 'nuntius/configuration'
require 'nuntius/active_record_helpers'

module Nuntius
  # Configuration
  class Error < StandardError; end

  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end

    def message(event)
      return unless event

      Nuntius::MessengerJob.perform_later(@obj, event, @params)
    end

    def with(obj, params = {})
      @obj = obj
      @params = params

      self
    end
  end
end
