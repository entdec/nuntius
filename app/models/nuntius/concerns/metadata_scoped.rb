# frozen_string_literal: true

module Nuntius::MetadataScoped
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { instance_exec(&Nuntius.config.visible_scope) }
    before_save :add_metadata
  end

  private

  def add_metadata
    self.metadata ||= {}
    Nuntius.config.metadata_fields.each do |field, data|
      metadata[field] ||= instance_exec(data[:current])
    end
    instance_exec(&Nuntius.config.add_metadata)
  end
end
