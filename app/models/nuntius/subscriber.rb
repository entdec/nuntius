# frozen_string_literal: true

module Nuntius
  class Subscriber < ApplicationRecord
    belongs_to :list
    belongs_to :nuntiable, polymorphic: true, optional: true

    scope :subscribed, -> { where(unsubscribed_at: nil) }

    def name
      [first_name, last_name].compact.join(" ").presence || email
    end

    def first_name
      return nuntiable.first_name if nuntiable.respond_to?(:first_name)

      super
    end

    def last_name
      return nuntiable.last_name if nuntiable.respond_to?(:last_name)

      super
    end

    def email
      return nuntiable.email if nuntiable.respond_to?(:email)

      super
    end
  end
end
