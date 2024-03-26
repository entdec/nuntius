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
        # # puts "___nuntius_state_machine_events: #{___nuntius_state_machine_events} #{self.class.name} #{object_id}"
        # puts "Nuntius.events: #{Thread.current['___nuntius_state_machine_events']}"
        # binding.pry
        Thread.current['___nuntius_state_machine_events']&.each do |event|
          Nuntius.event(event[:event], event[:object])
        end
        # After events were generated we can clear
        Thread.current['___nuntius_state_machine_events'] = []
      end

      state_machine do
        after_transition any => any do |record, transition|
          Thread.current['___nuntius_state_machine_events'] ||= []
          Thread.current['___nuntius_state_machine_events'] << { event: transition.event, object: record, class: record.class.name, id: record.id }
        end
      end
    end
  end
end
