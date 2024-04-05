# frozen_string_literal: true

module Nuntius
  class RetrieveInboundMailService < ApplicationService
    context do
      attribute :settings
    end

    def perform
      settings = context.settings
      settings.merge!(address: context.settings[:host],
        port: context.settings[:port],
        enable_ssl: context.settings[:enable_ssl],
        user_name: context.settings[:username],
        password: context.settings[:password])
      Mail::IMAP.new(settings).all do |message, imap, uid|
        inbound_message = Nuntius::InboundMessage.find_or_initialize_by(transport: "mail", provider: "imap", provider_id: message.message_id)
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

          if context.settings[:delete_after_processing]
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
  end
end
