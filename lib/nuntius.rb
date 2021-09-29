# frozen_string_literal: true

require 'auxilium'
require 'inky'
require 'httpclient'
require 'liquor'
require 'premailer'
require 'state_machines-activerecord'

require 'nuntius/deprecator'
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

    def event(event, obj, params = {})
      return unless event
      return unless obj.nuntiable?
      return unless templates?(obj, event)

      options = params[:options] || {}

      if options[:perform_now] == true
        Nuntius::MessengerJob.perform_now(obj, event.to_s, params)
      else
        job = Nuntius::MessengerJob
        job.set(wait: options[:wait]) if options[:wait]
        job.perform_later(obj, event.to_s, params)
      end
    end

    def active_storage_enabled?
      ActiveRecord::Base.connection.table_exists? 'active_storage_attachments'
    end

    def templates?(obj, event)
      Nuntius::Template.where(klass: Nuntius::BaseMessenger.class_names_for(obj),
                              event: Nuntius::BaseMessenger.event_name_for(
                                obj, event
                              )).where(enabled: true).count.positive?
    end
  end

  # Include helpers
  ActiveSupport.on_load(:active_record) do
    include Nuntius::ActiveRecordHelpers
  end
end
