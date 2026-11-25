module Nuntius
  module Concerns
    # nuntiable use_state_machine: true: a transition sends the templates for
    # the state it goes to (Triggers), once its transaction commits. It's
    # recorded in the transaction (Nuntius::Event), so a rollback takes it
    # along; a transition that stays in its state sends nothing.
    module EventsTransaction
      extend ActiveSupport::Concern

      included do
        state_machine do
          after_transition any => any do |object, transition|
            next if transition.loopback? || !object.persisted?
            next unless Nuntius.templates?(object, transition.to_name)

            Nuntius::Event.find_or_create_by!(
              transitionable_type: object.class.name,
              transitionable_id: object.id,
              transition_to: transition.to.to_s,
              transition_attribute: transition.attribute.to_s
            ) do |event|
              event.transition_event = transition.event.to_s
              event.transition_from = transition.from.to_s
            end
          end
        end

        after_commit :dispatch_nuntius_events
      end

      def dispatch_nuntius_events
        Nuntius::Event
          .where(transitionable_type: self.class.name, transitionable_id: id)
          .select(:transition_to, :transition_attribute).distinct.each do |event|
          # Claim the events before dispatching: another commit of this object, in this process or
          # another, may be dispatching them as well, and only the one that deletes them sends
          claimed = Nuntius::Event.where(transitionable_type: self.class.name, transitionable_id: id,
            transition_to: event.transition_to.to_s, transition_attribute: event.transition_attribute).delete_all
          next if claimed.zero?

          Nuntius.fire(event.transition_to.to_sym, self)
        end
      end
    end
  end
end
