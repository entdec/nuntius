# frozen_string_literal: true

module Nuntius::ActiveRecordHelpers
  extend ActiveSupport::Concern

  included do
    delegate :nuntiable?, to: :class
  end

  class_methods do
    def nuntiable(options = {})
      has_many :messages, as: :nuntiable, class_name: 'Nuntius::Message'
      Nuntius::InitializeForClassService.new(self, options).call
      class_variable_set(:@@_is_nuntiable, true)
    end

    def nuntiable?
      return false unless class_variable_defined?(:@@_is_nuntiable)

      class_variable_get(:@@_is_nuntiable)
    end
  end
end
