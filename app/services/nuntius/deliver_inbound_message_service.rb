# frozen_string_literal: true

module Nuntius
  class DeliverInboundMessageService < ApplicationService
    context do
      attribute :inbound_message
    end

    def perform
      context.inbound_message.update!(status: "delivered")
      result = Nuntius::BaseMessageBox.deliver(context.inbound_message)
      context.inbound_message.update!(status: "processed") if result
    end
  end
end
