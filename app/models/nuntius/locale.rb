# frozen_string_literal: true

module Nuntius
  class Locale < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped
    include Nuntius::Concerns::Yamlify

    yamlify :data
    yamlify :metadata
  end
end
