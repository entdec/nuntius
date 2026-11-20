# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class RetrieveMailJob < ApplicationJob
    def perform
      klasses = Nuntius::BaseMessageBox.message_box_for(transport: :mail)

      klasses.each do |klass|
        klass.mailboxes.each do |mailbox, settings|
          retrieve(klass, mailbox, settings)
        end
      end

      Nuntius::InboundMessage.where(status: "pending").each do |message|
        Nuntius::DeliverInboundMessageJob.perform_later(message)
      end
    end

    private

    # A mailbox that can't be fetched (it can't connect or sign in, say) is reported, and the others are still
    # fetched. Either way its message box hears how it went (see BaseMessageBox.fetched).
    def retrieve(klass, mailbox, settings)
      RetrieveInboundMailService.perform(settings: settings, message_box: klass.name, mailbox: mailbox)
    rescue => e
      Rails.error.report(e, handled: true, context: {message_box: klass.name, mailbox: mailbox})
      klass.fetched(mailbox, e)
    else
      klass.fetched(mailbox)
    end
  end
end
