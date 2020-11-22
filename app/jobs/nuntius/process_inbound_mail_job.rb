# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class ProcessInboundMailJob < ApplicationJob
    def perform(inbound_mail, mail)
      inbound_mail.update(status: 'delivered')
      mail
    end
  end
end
