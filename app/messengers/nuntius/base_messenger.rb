# frozen_string_literal: true

module Nuntius
  class BaseMessenger
    delegate :liquid_variable_name_for, :class_name_for, to: :class

    def initialize(object, event, params = {})
      @object = object
      @event = event
      @params = params
    end

    # Calls the event method on the messenger
    def call
      send(@event.to_sym, @object, @params)
    end

    # Returns the relevant templates for the object / event combination
    def templates
      Template.where(klass: class_name_for(@object), event: @event)
    end

    # Turns the templates in messages, and dispatches the messages to transports
    def self.dispatch(filtered_templates)
      filtered_templates.each do |template|
        msg = template.new_message
        transport = BaseTransport.class_from_name(template.transport).new
        transport.deliver(msg)
      end
    end

    def self.liquid_variable_name_for(obj)
      if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
        obj.first.class.name.demodulize.pluralize
      else
        obj.class.name.demodulize
      end
    end

    def self.class_name_for(obj)
      if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
        obj.first.class.name.demodulize
      else
        obj.class.name.demodulize
      end
    end
  end
end
