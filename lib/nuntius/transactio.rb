# frozen_string_literal: true

module Nuntius
  module Transactio
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      orchestrator = Evento::Orchestrator.new(self)
      if nuntiable_options[:life_cycle]
        orchestrator.define_event_methods_on(messenger, life_cycle: true) do |object, options = {}|
        end
      end

      orchestrator = Evento::Orchestrator.new(self)
      orchestrator.after_transaction_log_commit(:nuntius) do |transaction_log_entry|
        resource = transaction_log_entry.transaction_loggable
        event = transaction_log_entry.event

        if resource.present? && event.present? && resource.nuntiable?
          params = Nuntius.config.default_params(transaction_log_entry)

          Nuntius.event(event, resource, params)
          Nuntius.event("save", resource, params) if %w[create update].include?(event)
        end
      end
    end
  end
end
