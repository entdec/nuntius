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
        self.class.transaction do
          events = Nuntius::Event
                     .where(transitionable_type: self.class.to_s, transitionable_id: self.id)
                     .lock("FOR UPDATE OF nuntius_events SKIP LOCKED")

          events.find_each do |transition|
            begin
              Nuntius.event(transition.transition_event.to_sym, transition.transitionable)
              transition.destroy!
            rescue => e
              Rails.logger.error("Failed to dispatch Nuntius event #{transition.id}: #{e.message}")
            end
          end
        end
      end
    end
  end
end
