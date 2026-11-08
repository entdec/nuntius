# frozen_string_literal: true

class AccountDrop < ApplicationDrop
  delegate :name, to: :@object

  def users
    @object.users.map(&:to_liquid)
  end

  def logo
    ActiveStorageAttachedOneDrop.new(@object.logo)
  end

  def attachments
    ActiveStorageAttachedManyDrop.new(@object.attachments)
  end
end
