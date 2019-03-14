# frozen_string_literal: true

module ActiveRecordHelpers
  extend ActiveSupport::Concern

  class_methods do
    def nuntiable
      has_many :messages, as: :nuntiable, class_name: 'Nuntius::Message'
      Nuntius.config.nuntiable_class_names << self.name unless Nuntius.config.nuntiable_class_names.include? self.name

      raise "Nuntius Messenger missing for class #{self.name}, please create a #{Nuntius::BaseMessenger.messenger_name_for_class(self.name)}" unless Nuntius::BaseMessenger.messenger_for_class(self.name)
    end
  end
end
