# frozen_string_literal: true

require 'query_constructor'
module Nuntius

  module AutoMessageWithNuntius
    extend ActiveSupport::Concern
    included do
      after_commit do |resource_state_transition|
        Nuntius.with(resource_state_transition.resource).message(event.to_s)
      end
    end
  end

  class InitializeForClassService < ApplicationService
    attr_reader :klass, :name, :options

    def initialize(klass, options = {})
      @klass = klass
      @name = klass.name
      @options = options
    end

    def perform
      raise "Nuntius Messenger missing for class #{name}, please create a #{messenger}" unless messenger

      add_to_config
      create_events
      override_devise if options[:override_devise]

      assoc = klass.reflect_on_all_associations.find{ |a| a.name == :resource_state_transitions }
      if options[:use_state_machine] && assoc
        assoc.klass.send(:include, AutoMessageWithNuntius)
      end
    end

    private

    def override_devise
      klass.send(:define_method, :send_devise_notification) { |notification, *params| Nuntius.with(self, devise: params).message(notification.to_s) }
    end

    def add_to_config
      Nuntius.config.nuntiable_class_names << name unless Nuntius.config.nuntiable_class_names.include?(name)
    end

    def nuntiable_events
      events = []
      events += nuntiable_events_from_state_machine if options[:use_state_machine]
      events += nuntiable_events_from_devise if options[:override_devise]
      events
    end

    def nuntiable_events_from_state_machine
      if klass.respond_to?(:aasm)
        klass.aasm.events.map(&:name)
      elsif klass.respond_to?(:state_machine) && klass.state_machine.respond_to?(:events)
        klass.state_machine.events.map(&:name)
      else
        []
      end
    end

    def nuntiable_events_from_devise
      I18n.t('devise.mailer').keys.map(&:to_s)
    end

    # add all known events to the messenger class as actions
    def create_events
      nuntiable_events.each do |event_name|
        next if messenger.method_defined?(event_name)

        messenger.send(:define_method, event_name) { |object, params = {}| }
      end
    end

    def messenger
      Nuntius::BaseMessenger.messenger_for_class(name)
    end
  end
end
