module Nuntius
  class Subscriber < ApplicationRecord
    belongs_to :list

    def name
      [first_name, last_name].join(' ')
    end
  end
end
