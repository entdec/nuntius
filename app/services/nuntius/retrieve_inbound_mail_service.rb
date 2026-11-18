# frozen_string_literal: true

module Nuntius
  class RetrieveInboundMailService < ApplicationService
    # The settings of a mailbox, and the message box and its mailbox (by name) its messages are recorded as fetched by
    context do
      attribute :settings
      attribute :message_box
      attribute :mailbox
    end

    def perform
      # The Mail gem's address and user_name, or host and username
      settings = context.settings.to_h.symbolize_keys
      settings[:address] ||= settings[:host]
      settings[:user_name] ||= settings[:username]
      Mail::IMAP.new(settings).all do |message, imap, uid|
        inbound_message = find_or_initialize_inbound_message(message)
        if inbound_message.new_record?
          inbound_message.digest = Digest::SHA256.hexdigest(message.to_s)
          inbound_message.from = message.from
          inbound_message.to = message.to
          inbound_message.cc = message.cc
          inbound_message.text = message.text_part&.decoded
          inbound_message.html = message.html_part&.decoded
          inbound_message.subject = message.subject
          inbound_message.save!

          si = StringIO.new
          si.write(message.to_s)
          si.rewind
          inbound_message.raw_message.attach(io: si, filename: message.message_id)

        elsif inbound_message.status == "processed" && Digest::SHA256.hexdigest(message.to_s) == Digest::SHA256.hexdigest(inbound_message.raw_message.download)

          if settings[:delete_after_processing]
            imap.uid_store(uid, "+FLAGS", [Net::IMAP::DELETED])
            imap.expunge
          else
            existing_mailboxes = imap.list("", "*").map(&:name)
            unless existing_mailboxes.include?("Archive")
              imap.create("Archive")
            end
            imap.uid_copy(uid, "Archive")

            imap.uid_store(uid, "+FLAGS", [Net::IMAP::DELETED])
            imap.expunge
          end
        end
      end
    end

    private

    # Once per mailbox: the same mail in two mailboxes is two messages. One fetched before messages had their mailbox
    # is its message box's default mailbox's.
    def find_or_initialize_inbound_message(message)
      found = Nuntius::InboundMessage.where(transport: "mail", provider: "imap", provider_id: message.message_id)
      found.find_by(message_box: context.message_box, mailbox: context.mailbox&.to_s) ||
        (found.find_by(message_box: nil, mailbox: [nil, "default"]) if context.mailbox.to_s == "default") ||
        found.new(message_box: context.message_box, mailbox: context.mailbox&.to_s)
    end
  end
end
