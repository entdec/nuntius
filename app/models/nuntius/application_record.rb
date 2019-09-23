# frozen_string_literal: true

require_relative 'concerns/metadata_scoped'

module Nuntius
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true

    def to_liquid
      "#{self.class.name}Drop".constantize.new(self)
    end
  end
end
