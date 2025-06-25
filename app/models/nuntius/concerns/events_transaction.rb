module Nuntius
  module Concerns
    module EventsTransaction
      extend ActiveSupport::Concern

      included do
        state_machine.events.map(&:name)
          .reject { |event_name| messenger.method_defined?(event_name) }
          .each do |event_name|
          messenger.send(:define_method, event_name) { |object, options = {}| }
        end

        state_machine do
          after_transition any => any do |object, transition|
            return unless object.persisted?

            Nuntius::Event.find_or_create_by!(
              transitionable_type: object.class.name,
              transitionable_id: object.id,
              # transitionable: object,
              transition_event: transition.event.to_s,
              transition_attribute: transition.attribute.to_s
            ) do |event|
              event.transition_from = transition.from.to_s
              event.transition_to = transition.to.to_s
            end
          end
        end

        after_commit :dispatch_nuntius_events
      end

      def dispatch_nuntius_events
        # puts "Dispatching Nuntius events for #{self.class.name} with ID #{id}"
        # puts "Nuntius::Event count: #{Nuntius::Event.count}"
        # binding.break
        Nuntius::Event
          .where(transitionable: self)
          .includes(:transitionable)
          .select(:transition_event, :transitionable_type, :transitionable_id).distinct.each do |event|
          # puts "Dispatching event: #{event.transition_event} for #{event.transitionable_type} with ID #{event.transitionable_id}"
          # binding.break
          Nuntius.event(event.transition_event.to_sym, event.transitionable)
        end
      end
    end
  end
end
