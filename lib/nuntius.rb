# frozen_string_literal: true

require 'inky'
require 'liquor'
require 'premailer'
require 'state_machines-activerecord'

require 'nuntius/engine'
require 'nuntius/configuration'
require 'nuntius/active_record_helpers'
require 'nuntius/active_storage_helpers'

module Nuntius
  ROOT_PATH = Pathname.new(File.join(__dir__, '..'))

  class Error < StandardError; end

  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end

    def message(event)
      return unless event

      Nuntius::MessengerJob.perform_later(@obj, event.to_s, @params)
    end

    def with(obj, params = {})
      @obj = obj
      @params = params

      self
    end
  end

  # Include helpers
  ActiveSupport.on_load(:active_record) do
    include ActiveRecordHelpers
  end
end
