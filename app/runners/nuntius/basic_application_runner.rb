# frozen_string_literal: true

module Nuntius
  # This is the default runner used for runners in Nuntius, you can insert your
  # own in the Nuntius configuration in your Rails Nuntius initializer.
  class BasicApplicationRunner
    def call
      perform
    end
  end
end
