# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class MessengerJob < ApplicationJob
    # TODO: add this as configuration
    # queue_as :message

    def perform(obj, event, params = {})
      klass = "#{Nuntius::BaseMessenger.class_name_for(obj)}Messenger".constantize
      klass.new(obj, event, params).call
    end
  end
end
