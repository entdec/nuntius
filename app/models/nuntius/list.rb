# frozen_string_literal: true

require_relative 'concerns/metadata_scoped'

module Nuntius
  class List < ApplicationRecord
    include MetadataScoped

    has_many :subscribers, counter_cache: :subscribers_count
  end
end
