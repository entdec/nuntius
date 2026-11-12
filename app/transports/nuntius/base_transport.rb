# frozen_string_literal: true

module Nuntius
  class BaseTransport
    def kind
      self.class.name.demodulize.gsub(/Transport$/, "").underscore.to_sym
    end

    # Gives the message to its providers (see providers), by priority: all of
    # a priority at once, the next ones after their timeouts. A message no
    # provider handles has no recipient.
    def deliver(message)
      message.update(transport: kind.to_s) if message.transport.blank?
      candidates = providers(message: message)
      return message.no_recipient if candidates.empty? && providers.any?

      wait_time = 0
      candidates.group_by { |hash| hash[:priority] }.sort.each do |_priority, providers_for_priority|
        time_out = 0
        providers_for_priority.each do |hash|
          message.update(provider: hash[:provider].to_s) if message.provider.blank?

          Nuntius::TransportDeliveryJob.set(wait: !Rails.env.development? && !Rails.env.test? && wait_time).perform_later(hash[:provider].to_s, message)
          time_out += hash[:timeout].seconds if hash[:timeout].positive?
        end
        wait_time += time_out
      end
    end

    # Its configured providers, of a priority, and those that handle the
    # message's address (see BaseProvider.handles?)
    def providers(priority = nil, message: nil)
      results = Nuntius.config.providers[kind].to_a
      results = results.select { |provider| provider[:priority] == priority } if priority
      results = results.select { |provider| handles?(provider, message) } if message
      results
    end

    def self.class_from_name(name)
      Nuntius.const_get("#{name}_transport".camelize)
    end

    private

    # Providers without a class of their own handle everything
    def handles?(provider, message)
      klass = BaseProvider.class_from_name(provider[:provider], kind)
      klass.nil? || klass.handles?(message.to)
    end
  end
end
