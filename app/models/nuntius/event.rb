module Nuntius
  class Event < ApplicationRecord
    belongs_to :transitionable, polymorphic: true
    validates :transition_event, :transition_attribute, :transition_from, :transition_to, presence: true
  end
end