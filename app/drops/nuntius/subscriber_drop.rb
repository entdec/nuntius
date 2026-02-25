# frozen_string_literal: true

module Nuntius
  class SubscriberDrop < ApplicationDrop
    delegate :id, :first_name, :last_name, :name, :list, :metadata, to: :@object
  end
end
