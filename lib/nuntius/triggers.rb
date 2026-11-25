# frozen_string_literal: true

module Nuntius
  # What a nuntiable class's templates are sent on, its triggers, each named
  # for what its object is or what happened to it:
  #
  # - a state its state machine's events go to (nuntiable use_state_machine:
  #   true): a template for Order on shipped, not on the event ship. A
  #   transition that stays in its state goes nowhere, and sends nothing;
  # - created, updated, saved and destroyed (life_cycle: true);
  # - those it fires itself by name, Nuntius.fire(:reminded, order), declared
  #   with nuntiable triggers: %i[reminded], or by a messenger's methods;
  # - before and after its timestamps (a messenger's, see Timestamp).
  module Triggers
    LIFE_CYCLE = %i[created updated saved destroyed].freeze

    # Nuntius 1's names for the life cycle (Nuntius.event(:create, order))
    OLD_LIFE_CYCLE = {create: :created, update: :updated, save: :saved, destroy: :destroyed}.freeze

    module_function

    # Its states, life cycle and own named triggers (not its messenger's or
    # timestamps'); nothing for a class that isn't nuntiable
    def for(model)
      options = options_of(model)
      return [] unless options

      triggers = []
      triggers += states(model) if options[:use_state_machine] || options[:state_machine]
      triggers += LIFE_CYCLE if options[:life_cycle]
      triggers += Array(options[:triggers]).map(&:to_sym)
      triggers.uniq
    end

    # The states its events go to: a transition that stays in its state
    # (any => any, active: :active) goes to none
    def states(model)
      return [] unless model.respond_to?(:state_machines)

      model.state_machines.values.flat_map { |machine| machine.events.flat_map { |event| targets(event) } }.uniq
    end

    # The states a state machine event goes to, without staying where it is
    def targets(event)
      event.branches.flat_map do |branch|
        branch.state_requirements.flat_map do |requirement|
          to = requirement[:to].respond_to?(:values) ? requirement[:to].values : []
          from = requirement[:from].respond_to?(:values) ? requirement[:from].values : nil
          to.compact.reject { |state| from == [state] }
        end
      end.uniq
    end

    # The state machine event of its model by that name, if there is one
    def state_machine_event(model, name)
      return unless model.respond_to?(:state_machines)

      model.state_machines.values.lazy.filter_map { |machine| machine.events[name.to_sym] }.first
    end

    # Its nuntiable options, or its superclass's (an STI subclass's are its base class's)
    def options_of(model)
      return unless model.is_a?(Class)

      model.ancestors.lazy.select { |ancestor| ancestor.is_a?(Class) && ancestor.respond_to?(:nuntiable?) && ancestor.instance_variable_defined?(:@_nuntius_nuntiable_options) }
        .map(&:nuntiable_options).first
    end
  end
end
