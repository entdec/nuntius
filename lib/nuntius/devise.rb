# frozen_string_literal: true

module Nuntius
  module Devise
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      orchestrator = Evento::Orchestrator.new(self)
      orchestrator.define_event_methods_on(messenger, devise: true) { |object, options = {}| }

      orchestrator.override_devise_notification do |notification, *devise_params|
        # All notifications have either a token as the first param, or nothing
        Nuntius.event(notification, self, {token: devise_params.first})
      end
    end
  end
end
