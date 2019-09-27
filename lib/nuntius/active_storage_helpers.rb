# frozen_string_literal: true

module Nuntius::ActiveStorageHelpers
  extend ActiveSupport::Concern
  included do
    has_many :attachments
  end
end
