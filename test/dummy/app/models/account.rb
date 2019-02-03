# frozen_string_literal: true

class Account < ApplicationRecord
  after_create :send_create
  after_update :send_update
  before_destroy :send_destroy

  private

  def send_create
    Nuntius.with(self).message('created')
  end

  def send_update
    Nuntius.message(self).message('updated')
  end

  def send_destroy
    Nuntius.message(self).message('destroyed')
  end
end
