# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class RetrieveMailJob < ApplicationJob
    def perform
      klasses = Nuntius::BaseMessageBox.message_box_for(transport: :mail)

      klasses.each do |klass|
        RetrieveInboundMailService.perform(settings: klass.settings)
      end

      Nuntius::InboundMessage.where(status: "pending").each do |message|
        Nuntius::DeliverInboundMessageJob.perform_later(message)
      end
    end
  end
end
