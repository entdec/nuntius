# frozen_string_literal: true

class Account < ApplicationRecord
  after_create :send_create
  after_update :send_update
  before_destroy :send_destroy

  private

  def send_create
    Nuntius.message(self, 'create')
  end

  def send_update
    Nuntius.message(self, 'update')
  end

  def send_destroy
    Nuntius.message(self, 'destroy')
  end
end
