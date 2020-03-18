module Nuntius
  class Attachment < ApplicationRecord
    has_and_belongs_to_many :messages, :class_name => 'Message'

    delegate [:download, :content_type, :file_name], to: :content
  end
end
