# frozen_string_literal: true

class UserDrop < ApplicationDrop
  delegate :name, :email, :state, :born_on, to: :@object

  def active?
    @object.state == "active"
  end
end
