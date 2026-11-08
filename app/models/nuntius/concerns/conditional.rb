# frozen_string_literal: true

module Nuntius
  module Concerns
    # Templates and campaigns send only when their conditions are met (see
    # Conditions), checked with the Liquid variables a message renders with
    module Conditional
      extend ActiveSupport::Concern

      def conditions=(value)
        super(Conditions.new(value).to_h)
      end

      def conditions_met?(assigns)
        Conditions.new(conditions).met?(assigns)
      end
    end
  end
end
