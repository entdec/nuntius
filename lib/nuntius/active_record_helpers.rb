# frozen_string_literal: true

require_relative "nuntiable"
require_relative "devise"
require_relative "state_machine"
require_relative "life_cycle"
# require_relative "transactio"

module Nuntius::ActiveRecordHelpers
  extend ActiveSupport::Concern

  included do
    delegate :nuntiable?, to: :class
  end

  class_methods do
    def nuntiable(options = {})
      @_nuntius_nuntiable_options = options
      include Nuntius::Nuntiable
      include Nuntius::StateMachine if options[:use_state_machine]
      include Nuntius::Devise if options[:override_devise]
      include Nuntius::LifeCycle if options[:life_cycle]
    end

    def nuntiable?
      included_modules.include?(Nuntius::Nuntiable)
    end
  end
end
