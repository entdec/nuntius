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
