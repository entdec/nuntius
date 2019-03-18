# frozen_string_literal: true

module Nuntius
  class BaseMessenger
    include ActiveSupport::Callbacks

    delegate :liquid_variable_name_for, :class_name_for, to: :class

    define_callbacks :dispatch
    # set_callback :transition, :after

    def initialize(object, event, params = {})
      @object = object
      @event = event
      @params = params
    end

    # Calls the event method on the messenger, which should return templates
    def call
      send(@event.to_sym, @object, @params)
    end

    # Turns the templates in messages, and dispatches the messages to transports
    def dispatch(filtered_templates)
      filtered_templates.each do |template|
        msg = template.new_message(@object, liquid_context)
        transport = BaseTransport.class_from_name(template.transport).new
        transport.deliver(msg)
      end
    end

    class << self
      def liquid_variable_name_for(obj)
        if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
          obj.first.class.name.demodulize.pluralize.underscore
        else
          obj.class.name.demodulize.underscore
        end
      end

      def class_name_for(obj)
        if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
          obj.first.class.name.demodulize
        else
          obj.class.name.demodulize
        end
      end

      def messenger_for_class(name)
        messenger_name_for_class(name).safe_constantize
      end

      def messenger_name_for_class(name)
        "#{name}Messenger"
      end

      def messenger_for_obj(obj)
        messenger_name_for_obj(obj).safe_constantize
      end

      def messenger_name_for_obj(obj)
        "#{Nuntius::BaseMessenger.class_name_for(obj)}Messenger"
      end
    end

    private

    # Returns the relevant templates for the object / event combination
    def templates
      Template.where(klass: class_name_for(@object), event: @event)
    end

    def liquid_context
      (@params || {}).merge(liquid_variable_name_for(@object) => @object,
                            'event' => @event)
    end
  end
end
