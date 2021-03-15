# frozen_string_literal: true

module Nuntius
  class InitializeForClassService < ApplicationService
    transaction false

    attr_reader :klass, :name, :options

    def initialize(klass, options = {})
      super()
      @klass = klass
      @name = klass.name
      @options = options
    end

    def perform
      raise "Nuntius Messenger missing for class #{name}, please create a #{messenger}" unless messenger

      add_to_config
      orchestrator = Evento::Orchestrator.new(klass)
      orchestrator.define_event_methods_on(messenger, state_machine: options[:use_state_machine], life_cycle: options[:life_cycle], devise: options[:override_devise]) { |object, params = {}| }

      if options[:override_devise]
        orchestrator.override_devise_notification do |notification, *devise_params|
          # All notifications have either a token as the first param, or nothing
          Nuntius.with(self, token: devise_params.first).message(notification)
        end
      end

      if options[:use_state_machine]
        orchestrator.after_audit_trail_commit(:nuntius) do |resource_state_transition|
          resource = resource_state_transition.resource
          Nuntius.with(resource).message(event.to_s) if resource.nuntiable?
        end
      end

      orchestrator.after_transaction_log_commit(:nuntius) do |transaction_log_entry|
        record  = transaction_log_entry.transaction_loggable
        event   = transaction_log_entry.event

        params = Nuntius.config.default_params(transaction_log_entry)

        Nuntius.with(record, params).message(event.to_s) if record.nuntiable? && event.present?
        Nuntius.with(record, params).message('save') if %w[create update].include?(event) && record.nuntiable?
      end
    end

    private

    def add_to_config
      Nuntius.config.add_nuntiable_class(klass)
    end

    def messenger
      Nuntius::BaseMessenger.messenger_for_class(name)
    end
  end
end
