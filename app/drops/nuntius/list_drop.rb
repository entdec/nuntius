# frozen_string_literal: true

module Nuntius
  class ListDrop < ApplicationDrop
    delegate :id, :name, :allow_unsubscribe, to: :@object
  end
end
