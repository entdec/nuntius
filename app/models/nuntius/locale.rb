# frozen_string_literal: true

module Nuntius
  class Locale < ApplicationRecord
    include Nuntius::Concerns::Owned
    include Nuntius::Concerns::Yamlify

    yamlify :data
  end
end
