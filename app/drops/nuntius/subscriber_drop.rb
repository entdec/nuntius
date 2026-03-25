# frozen_string_literal: true

module Nuntius
  class SubscriberDrop < ApplicationDrop
    delegate :id, :first_name, :last_name, :name, :list, :metadata, :unsubscribed_at, to: :@object

    def subscribed?
      @object.unsubscribed_at.nil?
    end

    def unsubscribed?
      !subscribed?
    end
  end
end
