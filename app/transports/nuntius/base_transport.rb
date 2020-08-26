# frozen_string_literal: true

module Nuntius
  class BaseTransport
    def kind
      self.class.name.demodulize.gsub(/Transport$/, '').underscore.to_sym
    end

    def deliver(message)
      priority = 1
      wait_time = 0
      message.update(transport: kind.to_s) if message.transport.blank?
      while (providers_for_priority = providers(priority)).present?
        time_out = 0
        providers_for_priority.each do |hash|
          if message.provider.blank?
            message.update(provider: hash[:provider].to_s)
          end

          Nuntius::TransportDeliveryJob.set(wait: !Rails.env.development? && wait_time).perform_later(hash[:provider].to_s, message)
          time_out += hash[:timeout].seconds if hash[:timeout].positive?
        end
        wait_time += time_out
        priority += 1
      end
    end

    def providers(priority = nil)
      results = Nuntius.config.providers[kind].to_a
      if priority
        results = results.select { |provider| provider[:priority] == priority }
      end
      results
    end

    def self.class_from_name(name)
      Nuntius.const_get("#{name}_transport".camelize)
    end
  end
end
