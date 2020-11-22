module Nuntius
  class InboundMessage < ApplicationRecord
    has_one_attached :raw_message
    has_many_attached :attachments

    def mail
      @mail ||= Mail.from_source(source)
    end

    def source
      @source ||= raw_message.download
    end
  end
end
