module Nuntius::ActiveStorageHelpers
  extend ActiveSupport::Concern
  included do
    has_many :assets
  end
end
