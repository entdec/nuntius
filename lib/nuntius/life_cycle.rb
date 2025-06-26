# frozen_string_literal: true

module Nuntius
  module LifeCycle
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      after_create_commit do
        Nuntius.event(:create, self)
        Nuntius.event(:save, self)
      end

      after_update_commit do
        Nuntius.event(:update, self)
        Nuntius.event(:save, self)
      end

      after_destroy_commit do
        Nuntius.event(:destroy, self)
      end

      %i[create destroy update save].each do |event_name|
        next if messenger.method_defined?(event_name)
        messenger.send(:define_method, event_name) { |object, options = {}| }
      end
    end
  end
end
