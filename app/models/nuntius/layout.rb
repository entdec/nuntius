# frozen_string_literal: true

require_relative 'concerns/metadata_scoped'

module Nuntius
  class Layout < ApplicationRecord
    include MetadataScoped

    # TODO: Attachments - use active-storage
    # This is to ensure layouts can have pictures etc
  end
end
