# frozen_string_literal: true

module Nuntius
  module StateMachine
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      orchestrator = Evento::Orchestrator.new(self)
      orchestrator.define_event_methods_on(messenger, state_machine: true) { |object, options = {}| }

      orchestrator.after_audit_trail_commit(:nuntius) do |resource_state_transition|
        resource = resource_state_transition.resource
        Nuntius.event(event, resource) if resource.nuntiable? && event.present?
      end
    end
  end
end
