# frozen_string_literal: true

module Nuntius
  class CustomMessenger < BaseMessenger
    # A hash's templates are of class Custom, on any event
    def handles_event? = true
  end
end
