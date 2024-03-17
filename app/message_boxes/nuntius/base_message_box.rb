# frozen_string_literal: true

# Base class for MessageBoxes
# These allow you to receive messages based on transport/provider and routes
module Nuntius
  # Message boxes process inbound messages
  class BaseMessageBox
    attr_reader :message

    def initialize(message)
      @message = message
    end

    # In case of mail transport mail will return the mail itself, using https://github.com/mikel/mail
    # For other transports  it will return nil.
    # @return [Mail::Message]
    def mail
      return nil unless self.class.transport.to_sym == :mail
      return @mail if @mail

      @mail = Mail.new(message.raw_message.download)
    end

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

      def route(attribute = :to, test = /.*/, to:)
        @routes ||= {}
        @routes[attribute] = {test: test, to: to}
        @routes
      end

      # Defines the settings
      def settings(hash = nil)
        @settings = hash if hash
        @settings
      end

      def deliver(message)
        klasses = message_box_for(transport: message.transport.to_sym, provider: message.provider.to_sym)
        klass, method = message_box_for_route(klasses, message)

        if method
          klass.new(message).send(method)
          true
        end
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

      def message_box_for_route(message_boxes, message)
        klass = message_boxes.find do |message_box|
          routes = message_box.routes || {}
          routes.any? do |attribute, hash|
            value = message.send(attribute)
            if value.is_a? Array
              value.any? { |value_item| hash[:test].match(value_item) }
            else
              hash[:test].match(value)
            end
          end
        end

        route = klass&.routes&.find do |attribute, hash|
          value = message.send(attribute)
          if value.is_a? Array
            value.any? { |value_item| hash[:test].match(value_item) }
          else
            hash[:test].match(value)
          end
        end

        [klass, route.last[:to]] if route
      end
    end
  end
end
