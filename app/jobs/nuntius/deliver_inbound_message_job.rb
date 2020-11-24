# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class DeliverInboundMessageJob < ApplicationJob
    def perform(inbound_message)
      Nuntius::DeliverInboundMessageService.new(inbound_message).call
    end
  end
end
