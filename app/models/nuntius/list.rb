module Nuntius
  class List < ApplicationRecord
    has_many :subscribers, counter_cache: :subscribers_count
  end
end
