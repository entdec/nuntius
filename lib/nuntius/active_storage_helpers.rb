module Nuntius::ActiveStorageHelpers
  extend ActiveSupport::Concern
  included do
    has_many :attachments
  end
end
