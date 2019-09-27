# frozen_string_literal: true

module Nuntius
  class Subscriber < ApplicationRecord
    belongs_to :list
    belongs_to :nuntiable, polymorphic: true, optional: true

    def name
      [first_name, last_name].join(' ')
    end
  end
end
