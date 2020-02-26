# frozen_string_literal: true

module Nuntius
  class Layout < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped

    # TODO: Attachments - use active-storage
    # This is to ensure layouts can have pictures etc
  end
end
