# frozen_string_literal: true

module Nuntius
  class BaseDriver
    def self.adapter(adapter)
      @adapter = adapter
    end

    def send
      # Not implemented
    end
  end
end
