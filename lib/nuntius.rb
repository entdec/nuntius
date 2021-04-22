# frozen_string_literal: true

require 'auxilium'
require 'inky'
require 'httpclient'
require 'liquor'
require 'premailer'
require 'state_machines-activerecord'

require 'nuntius/engine'
require 'nuntius/configuration'
require 'nuntius/active_record_helpers'
require 'nuntius/active_storage_helpers'
require 'nuntius/i18n_store'
require 'nuntius/mail_allow_list'

module Nuntius
  ROOT_PATH = Pathname.new(File.join(__dir__, '..'))

  class Error < StandardError; end

  class << self
    attr_reader :config

    def setup
      @config = Configuration.new
      yield config
    end

    def i18n_store
      @i18n_store ||= Nuntius::I18nStore.new
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

    def active_storage_enabled?
      ActiveRecord::Base.connection.table_exists? 'active_storage_attachments'
    end
  end

  # Include helpers
  ActiveSupport.on_load(:active_record) do
    include Nuntius::ActiveRecordHelpers
  end
end
