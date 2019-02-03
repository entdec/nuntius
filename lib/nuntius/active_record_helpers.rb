# frozen_string_literal: true

module ActiveRecordHelpers
  extend ActiveSupport::Concern

  class_methods do
    def nuntiable
      has_many :messages, as: :nuntiable, class_name: 'Nuntius::Message'
      Nuntius.config.classes << self unless Nuntius.config.classes.include? self
    end
  end
end
