# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class ProcessInboundMessageJob < ApplicationJob
    def perform(inbound_message)
      ProcessInboundMessageService.new(inbound_message).call
    end
  end
end
