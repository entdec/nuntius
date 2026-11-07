# frozen_string_literal: true

module Nuntius
  class TemplateDrop < ApplicationDrop
    delegate :id, :metadata, to: :@object

    describe :layout, drop: "Nuntius::LayoutDrop"

    # The old layout while the template still renders with it
    def layout
      @object.old_layout || @object.layout
    end
  end
end
