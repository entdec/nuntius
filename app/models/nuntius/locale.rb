# frozen_string_literal: true

module Nuntius
  class Locale < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped
  end
end
