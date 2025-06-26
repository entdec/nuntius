# frozen_string_literal: true

class UserDrop < ApplicationDrop
  delegate :name, :email, to: :@object
end
