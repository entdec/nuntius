# frozen_string_literal: true

require_relative "concerns/owned"

module Nuntius
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    include Liquidum::ToLiquid
  end
end
