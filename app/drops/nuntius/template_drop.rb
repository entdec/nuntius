# frozen_string_literal: true

module Nuntius
  class TemplateDrop < ApplicationDrop
    delegate :id, :metadata, :layout, to: :@object
  end
end
