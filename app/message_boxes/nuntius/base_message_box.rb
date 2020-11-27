# frozen_string_literal: true

module Nuntius
  # Message boxes process inbound messages
  class BaseMessageBox
    class << self
      attr_reader :routes

      def provider(value = nil)
        @provider = value.to_sym if value
        @provider
      end

      def transport(value = nil)
        @transport = value.to_sym if value
        @transport
      end

      def route(mapping = nil)
        @routes ||= {}
        @routes = @routes.merge(mapping) if mapping.is_a?(Hash)
        @routes
      end

      # Defines the settings
      def settings(hash = {})
        @settings = hash if hash
        @settings
      end

      def deliver(message)
        klasses = message_box_for(transport: message.transport.to_sym, provider: message.provider.to_sym)
        klass, method = message_box_for_route(klasses, message.to)

        klass.new(message).send(method) if method
      end

      def message_box_for(transport: nil, provider: nil)
        result = descendants
        result = result.select { |message_box| message_box.transport == transport } if transport
        result = result.select { |message_box| message_box.provider == provider } if provider
        result
      end

      private

      def descendants
        ObjectSpace.each_object(Class).select { |k| k < self }
      end

      def message_box_for_route(message_boxes, recipients)
        klass = message_boxes.find do |message_box|
          routes = (message_box.routes || {})
          routes.any? { |regexp, _method| [*recipients].any? { |recipient| regexp.match(recipient) } }
        end
        method = klass.routes.find { |regexp, _method| [*recipients].any? { |recipient| regexp.match(recipient) } }&.last if klass

        [klass, method] if method
      end
    end

    attr_reader :message

    def initialize(message)
      @message = message
    end
  end
end
