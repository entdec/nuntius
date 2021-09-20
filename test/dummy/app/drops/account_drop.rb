# frozen_string_literal: true

class AccountDrop < ApplicationDrop
  delegate :name, to: :@object

  def logo
    ActiveStorageAttachedOneDrop.new(@object.logo)
  end

  def attachments
    ActiveStorageAttachedManyDrop.new(@object.attachments)
  end
end
