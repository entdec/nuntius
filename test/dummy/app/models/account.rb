# frozen_string_literal: true

class Account < ApplicationRecord
  after_create :send_create
  after_update :send_update
  before_destroy :send_destroy

  has_one_attached :logo, service: Nuntius.config.active_storage_service
  has_many_attached :attachments, service: Nuntius.config.active_storage_service

  nuntiable

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
