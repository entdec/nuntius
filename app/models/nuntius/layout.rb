# frozen_string_literal: true

require_relative 'concerns/metadata_scoped'

module Nuntius
  class Layout < ApplicationRecord
    include MetadataScoped

  end
end
