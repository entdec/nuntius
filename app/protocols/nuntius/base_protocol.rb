# frozen_string_literal: true

module Nuntius
  class BaseProtocol
    # def self.protocol(protocol)
    #   @protocol = protocol
    # end

    def process
      # Not implemented
    end

    def drivers(priority = nil)
      results = Nuntius.config.drivers[kind].to_a
      results = results.select { |d| d[:priority] == priority } if priority
      results
    end

    def kind
      :null
    end

    private

    def with_message_instance(obj)
      message_instance = message_instance_for(obj)
      # message_instance.request_id = Praesens.request_id
      yield message_instance
      # Dont save the instance if it does not belong to the object
      message_instance.save if message_instance.persisted?
    rescue StandardError => e
      message_instance.state = :failed
      message_instance.feedback = { type: 'Error', info: e.message }
      message_instance.save if message_instance.persisted?
      Rails.logger.error "Message: #{e.message}: #{e.backtrace.join('; ')}"
    end

    def message_instance_for(obj)
      base = obj if obj.respond_to?(:message_instances)
      base ||= obj.shipment if obj.respond_to?(:shipment)
      base ||= obj.user if obj.respond_to?(:user)
      return base.message_instances.create(message: self, state: :sending) if base

      # Returning a blank instance if no message instance present, this way we can keep state but we will not save it.
      MessageInstance.new(message: self)
    end

  end
end
