# frozen_string_literal: true

module Nuntius
  class Layout < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped
    include Nuntius::Concerns::Yamlify

    has_many_attached :attachments, service: Nuntius.config.active_storage_service
    has_many :templates, dependent: :restrict_with_error

    yamlify :metadata
  end
end
