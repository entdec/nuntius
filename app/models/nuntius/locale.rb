# frozen_string_literal: true

module Nuntius
  class Locale < ApplicationRecord
    include Nuntius::Concerns::Owned
    include Nuntius::Concerns::Yamlify

    yamlify :data

    # The order their translations merge in, later ones winning (see I18nStore)
    scope :in_order, -> { order(:created_at, :id) }
  end
end
