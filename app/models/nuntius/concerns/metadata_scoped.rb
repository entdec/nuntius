# frozen_string_literal: true

module Nuntius::MetadataScoped
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { instance_exec(&Nuntius.config.visible_scope) }
    before_save :add_metadata
  end

  private

  def add_metadata
    instance_exec(&Nuntius.config.add_metadata)
  end
end
