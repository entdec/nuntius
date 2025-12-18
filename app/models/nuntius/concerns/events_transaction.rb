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
            if object.persisted? && Nuntius.templates?(object, transition.event)
              Nuntius::Event.find_or_create_by!(
                transitionable_type: object.class.name,
                transitionable_id: object.id,
                transition_event: transition.event.to_s,
                transition_attribute: transition.attribute.to_s
              ) do |event|
                event.transition_from = transition.from.to_s
                event.transition_to = transition.to.to_s
              end
            end
          end
        end

        after_commit :dispatch_nuntius_events
      end

      def dispatch_nuntius_events
        Nuntius::Event
          .where(transitionable_type: self.class.name,transitionable_id: self.id,)
          .includes(:transitionable)
          .select(:transition_event, :transitionable_type, :transitionable_id).distinct.each do |event|
          Nuntius.event(event.transition_event.to_sym, event.transitionable)
        end
      end
    end
  end
end
