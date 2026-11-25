# frozen_string_literal: true

module Nuntius
  # nuntiable life_cycle: true: its records send the templates for created,
  # updated, saved (either) and destroyed, once committed (Triggers)
  module LifeCycle
    extend ActiveSupport::Concern

    included do
      raise "#{name} must be nuntiable" unless nuntiable?

      after_create_commit do
        Nuntius.fire(:created, self)
        Nuntius.fire(:saved, self)
      end

      after_update_commit do
        Nuntius.fire(:updated, self)
        Nuntius.fire(:saved, self)
      end

      after_destroy_commit do
        Nuntius.fire(:destroyed, self)
      end
    end
  end
end
