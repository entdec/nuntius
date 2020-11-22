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

      def connect(hash = {})
        @settings = hash if hash
        @settings
      end

      def descendants
        ObjectSpace.each_object(Class).select { |k| k < self }
      end

      def for(transport: nil, provider: nil)
        result = descendants
        result = result.select { |message_box| message_box.transport == transport } if transport
        result = result.select { |message_box| message_box.provider == provider } if provider
        result
      end

      def for_route(message_boxes, recipients)
        klass = nil
        klass = message_boxes.find do |message_box|
          routes = (message_box.routes || {})
          routes.any? { |regexp, _method| [*recipients].any? { |recipient| regexp.match(recipient) } }
        end
        method = klass.routes.find { |regexp, _method| [*recipients].any? { |recipient| regexp.match(recipient) } }&.last if klass

        [klass, method] if method
      end
    end
  end
end
