# frozen_string_literal: true

module Nuntius::ActiveStorageHelpers
  extend ActiveSupport::Concern

  included do
    has_one_attached :content, service: Nuntius.config.active_storage_service
  end
end
