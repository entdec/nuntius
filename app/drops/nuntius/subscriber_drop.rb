# frozen_string_literal: true

module Nuntius
  class SubscriberDrop < ApplicationDrop
    delegate :id, :first_name, :last_name, :name, to: :@object
  end
end
