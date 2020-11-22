# frozen_string_literal: true

module Nuntius
  class DeliverInboundMessageService < ApplicationService
    transaction true

    attr_reader :inbound_message

    def initialize(inbound_message)
      super()
      @inbound_message = inbound_message
    end

    def perform
      inbound_message.update(status: 'delivered')
      Nuntius::BaseMessageBox.deliver(inbound_message)
    end
  end
end
