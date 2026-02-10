# frozen_string_literal: true

module Nuntius
  module Devise
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      I18n.t("devise.mailer").keys.map(&:to_s).each do |event_name|
        messenger.send(:define_method, event_name) { |object, options = {}| }
      end

      define_method(:send_devise_notification) do |notification, *devise_params|
        # All notifications have either a token as the first param, or nothing
        Nuntius.event(notification, self, {token: devise_params.first})
      end
    end
  end
end
