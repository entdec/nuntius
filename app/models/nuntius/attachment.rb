module Nuntius
  class Attachment < ApplicationRecord
    has_and_belongs_to_many :messages, class_name: 'Message'

    delegate :download, :content_type, :filename, :signed_id, to: :content

    begin
      has_one_attached :content, service: :nuntius
    rescue StandardError
      nil
    end
  end
end
