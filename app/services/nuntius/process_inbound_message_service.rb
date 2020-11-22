# frozen_string_literal: true

module Nuntius
  class ProcessInboundMessageService < ApplicationService
    transaction true

    attr_reader :inbound_message

    def initialize(inbound_message)
      super()
      @inbound_message = inbound_message
    end

    def perform
      inbound_message.update(status: 'delivered')
      klasses = Nuntius::BaseMessageBox.for(transport: inbound_message.transport.to_sym, provider: inbound_message.provider.to_sym)
      klass, method = Nuntius::BaseMessageBox.for_route(klasses, inbound_message.to)

      klass.new(inbound_message).send(method) if method
    end
  end
end
