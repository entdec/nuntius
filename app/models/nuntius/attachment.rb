module Nuntius
  class Attachment < ApplicationRecord
    has_and_belongs_to_many :messages, :class_name => 'Message'
  end
end
