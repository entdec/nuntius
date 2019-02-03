# frozen_string_literal: true

class AccountDrop < ApplicationDrop
  delegate :name, to: :@object
end
