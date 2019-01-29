# frozen_string_literal: true

class Account < ApplicationRecord
  after_create :send_create
  after_update :send_update
  before_destroy :send_destroy

  private

  def send_create
    Nuntius.with(self).message('create')
  end

  def send_update
    Nuntius.message(self).message('update')
  end

  def send_destroy
    Nuntius.message(self).message('destroy')
  end
end
