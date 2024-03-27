# frozen_string_literal: true

module Nuntius

  module StateMachine
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      state_machine.events.map(&:name)
                   .reject { |event_name| messenger.method_defined?(event_name) }
                   .each do |event_name|
        messenger.send(:define_method, event_name) { |object, options = {}| }
      end

      after_commit do
        Thread.current['___nuntius_state_machine_events']&.each do |event|
          Nuntius.event(event[:event], event[:object])
        end
        # After events are fired we can clear the events
        Thread.current['___nuntius_state_machine_events'] = []
      end

      state_machine do
        # This records events within the same thread, and clears them in the same thread.
        # A different thread is a different transaction.
        after_transition any => any do |record, transition|
          ___record__nuntius_state_machine_event(transition.event, record)
          ___record__nuntius_state_machine_event(:update, record)
          ___record__nuntius_state_machine_event(:save, record)
        end

        def ___record__nuntius_state_machine_event(event, object)
          Thread.current['___nuntius_state_machine_events'] ||= []
          Thread.current['___nuntius_state_machine_events'] << { event: event, object: object }
        end
      end
    end
  end
end
