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
          after_transition any => any do |record, transition|
            event = Nuntius::Event.find_or_initialize_by(
              transitionable_id: record.id,
              transitionable_type: record.class.to_s,
              transition_event: transition.event.to_s,
              transition_attribute: transition.attribute.to_s
            )
            event.update!(
              transition_from: transition.from.to_s,
              transition_to: transition.to.to_s
            )
          end
        end

        after_commit :dispatch_nuntius_events
      end

      def dispatch_nuntius_events
        Nuntius::Event
          .where(transitionable_type: self.class.to_s, transitionable_id: self.id)
          .includes(:transitionable)
          .select(:transition_event, :transitionable_type, :transitionable_id).distinct.each do |event|
          Nuntius.event(event.transition_event.to_sym, event.transitionable)
        end
      end
    end
  end
end
