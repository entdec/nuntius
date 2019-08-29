# frozen_string_literal: true

module Nuntius
  class ApplicationService
    attr_reader :raise_on_error
    # Main point of entry for services
    def call(raise_on_error = nil)
      @raise_on_error = raise_on_error unless raise_on_error.nil?
      result = nil
      ApplicationRecord.transaction do
        result = perform
        raise_if_needed(result)
      end
      result
    end

    def call!
      @raise_on_error = true
      call
    end

    private

    def raise_on_error?
      @raise_on_error
    end

    def raise_if_needed(result)
      return unless raise_on_error?
      return unless result.respond_to?(:invalid?) && result.invalid?

      errors = result.errors.full_messages.join(', ')
      request_log "raising: #{errors}"
      # request_log "Failing record: #{result.try(:attributes)}" rescue nil
      # request_log "origin: #{result.origin.attributes}" rescue nil
      # request_log "destination: #{result.destination.attributes)}" rescue nil
      log :error, "raising: #{errors}"
      raise BoxtureError, errors
    end

    def log(level, message)
      Rails.logger.send level, "#{self.class.name}: #{message}"
    end

    def request_log(message)
      Praesens.request_log("#{self.class.name}: #{message}")
    end
  end
end
