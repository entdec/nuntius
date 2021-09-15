# frozen_string_literal: true

module Nuntius
  class Layout < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped
    include Nuntius::Concerns::Yamlify

    has_many_attached :attachments
    has_many :templates, dependent: :restrict_with_error

    yamlify :metadata

    # TODO: Attachments - use active-storage
    # This is to ensure layouts can have pictures etc
  end
end
