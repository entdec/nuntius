# frozen_string_literal: true

module ActiveRecordHelpers
  extend ActiveSupport::Concern

  class_methods do
    def nuntiable(use_state_machine: false)
      has_many :messages, as: :nuntiable, class_name: 'Nuntius::Message'

      Nuntius.config.nuntiable_class_names << name unless Nuntius.config.nuntiable_class_names.include? name

      raise "Nuntius Messenger missing for class #{name}, please create a #{Nuntius::BaseMessenger.messenger_name_for_class(name)}" unless Nuntius::BaseMessenger.messenger_for_class(name)

      return if use_state_machine == false

      messenger = Nuntius::BaseMessenger.messenger_for_class(name)

      nuntiable_events = if respond_to?(:aasm)
                 aasm.events.map(&:name)
               elsif respond_to?(:state_paths)
                 state_machine.events.map(&:name)
               else
                 []
               end

      # add all state-machine events to the messenger class as actions
      nuntiable_events.each do |name|
        messenger.send(:define_method, name) { |object, params = {}| }
      end
    end
  end
end
