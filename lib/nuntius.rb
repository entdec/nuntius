# frozen_string_literal: true

require "nuntius/deprecator"
require "nuntius/engine"
require "nuntius/configuration"
require "nuntius/active_record_helpers"
require "nuntius/active_storage_helpers"
require "nuntius/i18n_store"
require "nuntius/mail_allow_list"

module Nuntius
  extend Configurable

  ROOT_PATH = Pathname.new(File.join(__dir__, ".."))

  class Error < StandardError; end

  class << self
    def i18n_store
      @i18n_store ||= Nuntius::I18nStore.new
    end

    #
    # Fires an event for use with templates with the object
    #
    # Nuntius.event(:your_event, car)
    #
    # When custom events are enabled you can also do the following:
    #
    # Nuntius.event('shipped', { shipped: { to: 'test@example.com', ref: 'Test-123'} }, attachments: [ { url: 'http://example.com' } ])
    #
    def event(event, obj, params = {})
      return unless event
      return unless obj.is_a?(Hash) || obj.nuntiable?
      return unless templates?(obj, event)

      params = (Nuntius.config.default_params(event, obj) || {}).merge(params)
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
      ActiveRecord::Base.connection.table_exists? "active_storage_attachments"
    end

    def templates?(obj, event)
      messenger = Nuntius::BaseMessenger.messenger_for_obj(obj).new(obj, event)
      return false unless messenger.is_a?(Nuntius::CustomMessenger) || messenger.respond_to?(event.to_sym)

      result = messenger.call
      return false if result == false

      messenger.templates.exists?
    end
  end

  # Include helpers
  ActiveSupport.on_load(:active_record) do
    include Nuntius::ActiveRecordHelpers
  end
end
