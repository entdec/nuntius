# frozen_string_literal: true

module Nuntius
  class OldLayoutDrop < LayoutDrop
    delegate :metadata, to: :@object
  end
end
