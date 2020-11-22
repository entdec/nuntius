# frozen_string_literal: true

module Nuntius
  class ApplicationService
    include ActiveSupport::Callbacks
    attr_reader :raise_on_error

    define_callbacks :perform

    # Main point of entry for services
    def call(raise_on_error = nil)
      @raise_on_error = raise_on_error unless raise_on_error.nil?
      if self.class.transaction
        ApplicationRecord.transaction(requires_new: true) { exec }
      else
        exec
      end
    end

    def call!
      @raise_on_error = true
      call
    end

    private

    def exec
      result = nil
      run_callbacks :perform do
        result = perform
      end
      raise_if_needed(result)
      result
    end

    def raise_on_error?
      @raise_on_error
    end

    def raise_if_needed(result)
      return unless raise_on_error?
      return unless result.respond_to?(:invalid?) && result.invalid?

      errors = result.errors.full_messages.join(', ')
      log :error, "raising: #{errors}"
      raise StandardError, errors
    end

    def log(level, message)
      Rails.logger.send level, "#{self.class.name}: #{message}"
    end

    def request_log(message)
      Praesens.request_log("#{self.class.name}: #{message}")
    end

    class << self
      def transaction(value = nil)
        @transaction = value unless value.nil?
        @transaction.nil? || @transaction == true
      end
    end
  end
end
