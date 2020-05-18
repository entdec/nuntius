# frozen_string_literal: true

module Nuntius
  module AutoMessageWithNuntius
    extend ActiveSupport::Concern
    included do
      after_commit do |resource_state_transition|
        resource = resource_state_transition.resource
        Nuntius.with(resource).message(event.to_s) if resource.nuntiable?
      end
    end
  end

  class InitializeForClassService < ApplicationService
    transaction false

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

      assoc = klass.reflect_on_all_associations.find { |a| a.name == :resource_state_transitions }
      if options[:use_state_machine] && assoc
        assoc.klass.send(:include, AutoMessageWithNuntius)
      end
    end

    private

    def override_devise
      klass.send(:define_method, :send_devise_notification) do |notification, *devise_params|
        # All notifications have either a token as the first param, or nothing
        Nuntius.with(self, token: devise_params.first).message(notification)
      end
    end

    def add_to_config
      Nuntius.config.add_nuntiable_class(klass)
    end

    # add all known events to the messenger class as actions
    def create_events
      Evento::Extractor.new(klass)
                       .extract(state_machine: options[:use_state_machine], devise: options[:override_devise])
                       .reject { |event_name| messenger.method_defined?(event_name) }
                       .each do |event_name|
        messenger.send(:define_method, event_name) { |object, params = {}| }
      end
    end

    def messenger
      Nuntius::BaseMessenger.messenger_for_class(name)
    end
  end
end
