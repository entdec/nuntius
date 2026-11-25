# frozen_string_literal: true

require "nuntius/deprecator"
require "nuntius/engine"
require "nuntius/configuration"
require "nuntius/active_record_helpers"
require "nuntius/active_storage_helpers"
require "nuntius/i18n_store"
require "nuntius/mail_allow_list"
require "nuntius/account_backfill"
require "nuntius/page_action"
require "nuntius/page"
require "nuntius/triggers"

module Nuntius
  extend Configurable

  ROOT_PATH = Pathname.new(File.join(__dir__, ".."))

  class Error < StandardError; end

  class << self
    #
    # Sends the templates for a trigger of the object: a state it went to, a
    # life cycle's (created, updated, saved, destroyed), or one of its own
    # (see Triggers), named for what happened:
    #
    #   Nuntius.fire(:reminded, order)
    #
    # For a hash, a custom trigger (templates of class Custom, on
    # shipped#shipped):
    #
    #   Nuntius.fire(:shipped, {shipped: {to: "test@example.com", ref: "Test-123"}}, attachments: [{url: "https://example.com"}])
    #
    def fire(name, obj, params = {})
      return unless name
      return unless obj.is_a?(Hash) || obj.nuntiable?
      return unless templates?(obj, name)

      params = (Nuntius.config.default_params(name, obj) || {}).merge(params)
      options = params[:options] || {}

      if options[:perform_now] == true
        Nuntius::MessengerJob.perform_now(obj, name.to_s, params)
      else
        job = Nuntius::MessengerJob
        job.set(wait: options[:wait]) if options[:wait]
        job.perform_later(obj, name.to_s, params)
      end
    end

    # Deprecated: Nuntius.fire, by the trigger's name. A state machine event
    # is sent as the one state it goes to (ship as shipped), and fails when it
    # goes to several or stays where it is; Nuntius 1's life cycle events as
    # their names now (create as created).
    def event(event, obj, params = {})
      return unless event

      name = trigger_for_event(event, obj)
      Nuntius::Deprecator.new.deprecation_warning("Nuntius.event", "Nuntius.fire(:#{name}, …): triggers are named for what happened, a state rather than its event")
      fire(name, obj, params)
    end

    # What Nuntius.event's event is now
    def trigger_for_event(event, obj)
      return event if obj.is_a?(Hash)

      model = obj.class
      return event if Triggers.for(model).include?(event.to_sym) || BaseMessenger.messenger_for_obj(obj).method_defined?(event.to_sym)
      return Triggers::OLD_LIFE_CYCLE[event.to_sym] if Triggers::OLD_LIFE_CYCLE.key?(event.to_sym)

      state_event = Triggers.state_machine_event(model, event)
      return event unless state_event

      targets = Triggers.targets(state_event)
      raise ArgumentError, "Nuntius.event(:#{event}): #{model.name}'s event #{event} goes to #{targets.any? ? "several states (#{targets.join(", ")})" : "no other state"}; fire a trigger of its own by name instead" unless targets.one?

      targets.first
    end

    def active_storage_enabled?
      ActiveRecord::Base.connection.table_exists? "active_storage_attachments"
    end

    def templates?(obj, event)
      messenger = Nuntius::BaseMessenger.messenger_for_obj(obj).new(obj, event)
      return false unless messenger.handles_event?

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
