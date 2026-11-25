# frozen_string_literal: true

module Nuntius
  module Devise
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      # Its notifications are its triggers, by Devise's names (reset_password_instructions)
      @_nuntius_nuntiable_options = nuntiable_options.merge(triggers: Array(nuntiable_options[:triggers]) + I18n.t("devise.mailer").keys.map(&:to_sym))

      define_method(:send_devise_notification) do |notification, *devise_params|
        # All notifications have either a token as the first param, or nothing
        Nuntius.fire(notification, self, {token: devise_params.first})
      end
    end
  end
end
