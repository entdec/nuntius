# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class ProcessInboundMessageJob < ApplicationJob
    def perform(inbound_message)
      Nuntius::DeliverInboundMessageService.perform(inbound_message: inbound_message)
    end
  end
end
