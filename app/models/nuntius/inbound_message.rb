module Nuntius
  class InboundMessage < ApplicationRecord
    has_one_attached :raw_message, service: Nuntius.config.active_storage_service
    has_many_attached :attachments, service: Nuntius.config.active_storage_service

    def mail
      @mail ||= Mail.from_source(source)
    end

    def source
      @source ||= raw_message.download
    end
  end
end
