# frozen_string_literal: true

module Nuntius
  # Custom messenger
  class CustomMessenger < BaseMessenger
    def respond_to_missing?(_symbol, _include_all)
      event != @event.to_sym
    end

    def method_missing(event, object = nil, params = {})
      super if event != @event.to_sym
    end
  end
end
