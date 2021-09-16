# frozen_string_literal: true

module Nuntius
  class LayoutDrop < ApplicationDrop
    delegate :name, :metadata, :layout, to: :@object

    def attachments
      ActiveStorageAttachedManyDrop.new(@object.attachments)
    end
  end
end
