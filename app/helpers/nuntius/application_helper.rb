# frozen_string_literal: true

module Nuntius
  module ApplicationHelper
    def present(model, presenter_class = nil)
      array = nil
      if model.is_a? Array
        array = model
        model = model.first
      end

      klass = presenter_class || "#{model.class}Presenter".constantize
      presenter = array ? array.map { |m| klass.new(m) } : klass.new(model)
      yield(presenter) if block_given?
    end

    def method_missing(method, *args, &block)
      if main_app.respond_to?(method)
        main_app.send(method, *args)
      else
        super
      end
    end
  end
end
