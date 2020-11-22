# frozen_string_literal: true

# Initializes the appropriate Messenger class and calls the event method
module Nuntius
  class RetrieveMailJob < ApplicationJob
    def perform
      mail_config = {
        'address' => 'imap.soverin.net',
        'port' => 993,
        'user_name' => 'support@degrunt.nl',
        'password' => 'FBbTprsMqAJlRHts',
        'ssl' => true
      }

      ::Mail.defaults do
        retriever_method :imap,
                         address: mail_config['address'],
                         port: mail_config['port'],
                         user_name: mail_config['user_name'],
                         password: mail_config['password'],
                         enable_ssl: mail_config['ssl']
      end

      ::Mail.all do |message, imap, uid|
        inbound_mail = Nuntius::InboundMail.find_or_create_by!(message_id: message.message_id,
                                                               digest: Digest::SHA256.hexdigest(message.to_s), state: 'pending')

        if inbound_mail.raw_mail.attached?
          if Digest::SHA256.hexdigest(message.to_s) == Digest::SHA256.hexdigest(inbound_mail.raw_mail.download)
            # Only if we have an attachment and it's digest is the same as we find in the mailbox, delete!
            # This never happens on the first round of fetching it.
            imap.store(uid, '+FLAGS', [:Deleted])
            Nuntius::ProcessInboundMailJob.set(wait: 2).perform_later(inbound_mail, mail)
          end
        else
          si = StringIO.new
          si.write(message.to_s)
          si.rewind
          inbound_mail.raw_mail.attach(io: si, filename: message.message_id)
        end
      end
    end
  end
end
