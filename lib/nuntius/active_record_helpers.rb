# frozen_string_literal: true

module ActiveRecordHelpers
  extend ActiveSupport::Concern

  class_methods do
    def nuntiable(use_state_machine: false)
      has_many :messages, as: :nuntiable, class_name: 'Nuntius::Message'

      Nuntius.config.nuntiable_class_names << self.name unless Nuntius.config.nuntiable_class_names.include? self.name

      raise "Nuntius Messenger missing for class #{self.name}, please create a #{Nuntius::BaseMessenger.messenger_name_for_class(self.name)}" unless Nuntius::BaseMessenger.messenger_for_class(self.name)

      if use_state_machine == true && respond_to?(:state_machine)
        messenger = Nuntius::BaseMessenger.messenger_for_class(self.name)

        # add all state-machine events to the messenger class as actions
        events = state_machine.events.map(&:name)
        events.each do |name|
          messenger.define_method(name) { |object, params = {}| }
        end
      end
    end

  end
end
