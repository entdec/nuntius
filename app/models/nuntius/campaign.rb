# frozen_string_literal: true

module Nuntius
  class Campaign < ApplicationRecord
    belongs_to :list
  end
end
