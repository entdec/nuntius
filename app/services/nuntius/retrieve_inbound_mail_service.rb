# frozen_string_literal: true

module Nuntius
  class RetrieveInboundMailService < ApplicationService
    transaction true

    def initialize(settings)
      @settings = settings
    end

    def perform
      Mail::IMAP.new(@settings).all do |message, imap, uid|
        inbound_message = Nuntius::InboundMessage.find_or_create_by!(transport: 'mail', provider: 'imap', provider_id: message.message_id,
                                                                     digest: Digest::SHA256.hexdigest(message.to_s), status: 'pending')
        inbound_message.from = message.from
        inbound_message.to = message.to
        inbound_message.text = message.body
        # inbound_message.metadata = params
        inbound_message.save!

        if inbound_message.raw_message.attached?
          if Digest::SHA256.hexdigest(message.to_s) == Digest::SHA256.hexdigest(inbound_message.raw_message.download)
            # Only if we have an attachment and it's digest is the same as we find in the mailbox, delete!
            # This never happens on the first round of fetching it.
            imap.store(uid, '+FLAGS', [Net::IMAP::DELETED])
            imap.expunge
            Nuntius::ProcessInboundMailJob.set(wait: 2).perform_later(inbound_message, mail)
          end
        else
          si = StringIO.new
          si.write(message.to_s)
          si.rewind
          inbound_message.raw_message.attach(io: si, filename: message.message_id)
        end
      end
    end
  end
end
