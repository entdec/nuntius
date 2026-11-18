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

    # The name of the mailbox the message was fetched from (see mailbox and mailboxes), nil when it wasn't fetched
    def mailbox
      message.mailbox
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

      # A mailbox it fetches mail from, by its name and its settings (for IMAP: address, port, user_name, password,
      # enable_ssl, …). Once for each:
      #
      #   mailbox :orders, address: "imap.example.com", user_name: "orders@example.com", password: ENV["ORDERS_PASSWORD"]
      #   mailbox :returns, address: "imap.example.com", user_name: "returns@example.com", password: ENV["RETURNS_PASSWORD"]
      def mailbox(name, settings = {})
        fixed_mailboxes[name.to_s] = settings
      end

      # Its mailboxes, by name: those of mailbox, and those the block gives (pairs of a name and its settings), which
      # is called each time mail is fetched, not when it's given, so they can come from the app's data:
      #
      #   mailboxes { Inbox.active.map { |inbox| [inbox.id, inbox.imap_settings] } }
      def mailboxes(&block)
        return @mailboxes_block = block if block

        dynamic = @mailboxes_block ? @mailboxes_block.call.to_h { |name, settings| [name.to_s, settings] } : {}
        fixed_mailboxes.merge(dynamic)
      end

      # Its one mailbox's settings: deprecated, it's mailbox :default
      def settings(hash = nil)
        if hash
          Nuntius::Deprecator.new.deprecation_warning("#{name}.settings", "use mailbox :default, settings")
          mailbox(:default, hash)
        end
        fixed_mailboxes["default"]
      end

      # To the message box that fetched it (see mailboxes), else to the one of its transport and provider with a route
      # for it
      def deliver(message)
        klasses = message_box_for(transport: message.transport.to_sym, provider: message.provider.to_sym)
        fetched_by = klasses.select { |klass| klass.name == message.message_box }
        klasses = fetched_by if fetched_by.any?
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

      def fixed_mailboxes
        @fixed_mailboxes ||= {}
      end

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
