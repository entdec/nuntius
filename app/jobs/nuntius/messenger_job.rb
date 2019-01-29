# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class MessengerJob < ApplicationJob
    # TODO: add this as configuration
    # queue_as :message

    def perform(obj, event, params = {})
      name = "#{Nuntius::BaseMessenger.class_name_for(obj)}Messenger"
      templates = name.constantize.new(obj, event, params).call

      Nuntius::BaseMessenger.dispatch(templates) if templates
    end
  end
end
