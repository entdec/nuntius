# frozen_string_literal: true

module ActiveRecordHelpers
  extend ActiveSupport::Concern

  class_methods do
    def nuntiable(options = {})
      has_many :messages, as: :nuntiable, class_name: 'Nuntius::Message'
      Nuntius::InitializeForClassService.new(self, options).call
    end
  end
end
