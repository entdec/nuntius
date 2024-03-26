# frozen_string_literal: true

module Nuntius
  module StateMachine
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      attr_accessor :___nuntius_state_machine_events

      state_machine.events.map(&:name)
                   .reject { |event_name| messenger.method_defined?(event_name) }
                   .each do |event_name|
        messenger.send(:define_method, event_name) { |object, options = {}| }
      end

      after_commit do
        ___nuntius_state_machine_events&.each do |event|
          Nuntius.event(event, self)
        end
      end

      state_machine do
        after_transition any => any do |record, transition|
          record.___nuntius_state_machine_events ||= []
          record.___nuntius_state_machine_events << transition.event
        end
      end
    end
  end
end
