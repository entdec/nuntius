# frozen_string_literal: true

module Nuntius
  class Deprecator
    def deprecation_warning(deprecated_method_name, message, _caller_backtrace = nil)
      message = "#{deprecated_method_name} is deprecated and will be removed from Nuntius | #{message}"
      Kernel.warn message
    end
  end
end
