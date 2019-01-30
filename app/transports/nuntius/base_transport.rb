# frozen_string_literal: true

module Nuntius
  class BaseTransport
    def kind
      self.class.name.demodulize.gsub(/Transport$/, '').underscore.to_sym
    end

    def deliver(message)
      priority = 1
      wait_time = 0
      while (providers_for_priority = providers(priority)).present?
        time_out = 0
        providers_for_priority.each do |hash|
          message.update(provider: hash[:provider].to_s) if message.provider.blank?
          Nuntius::TransportDeliveryJob.set(wait: wait_time).perform_later(hash[:provider].to_s, message)
          time_out += hash[:timeout].seconds if hash[:timeout].positive?
        end
        wait_time += time_out
        priority += 1
      end
    end

    def providers(priority = nil)
      results = Nuntius.config.providers[kind].to_a
      results = results.select { |provider| provider[:priority] == priority } if priority
      results
    end

    def self.class_from_name(name)
      Nuntius.const_get("#{name}_transport".camelize)
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
