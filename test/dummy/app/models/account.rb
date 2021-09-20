# frozen_string_literal: true

class Account < ApplicationRecord
  after_create :send_create
  after_update :send_update
  before_destroy :send_destroy

  has_one_attached :logo
  has_many_attached :attachments

  private

  def send_create
    Nuntius.event(:created, self)
  end

  def send_update
    Nuntius.event(:updated, self)
  end

  def send_destroy
    Nuntius.event(:detroyed, self)
  end
end
