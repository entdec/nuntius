# frozen_string_literal: true

require 'liquid'

require 'nuntius/engine'
require 'nuntius/configuration'

module Nuntius
  # Configuration
  class Error < StandardError; end

  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end

    def message(obj, event)
      MessageJob.perform_later(obj, event)
    end
  end
end
