# frozen_string_literal: true

module Nuntius
  # A layout from before Nuntius 2.0: HTML with {{ content }} where a template
  # or campaign goes. Templates and campaigns that aren't converted to the new
  # layouts yet still render with it. Removed in Nuntius 2.1.
  class OldLayout < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped
    include Nuntius::Concerns::Yamlify

    has_many_attached :attachments, service: Nuntius.config.active_storage_service
    has_many :templates, foreign_key: :old_layout_id, dependent: :restrict_with_error
    has_many :campaigns, foreign_key: :old_layout_id, dependent: :restrict_with_error

    yamlify :metadata
  end
end
