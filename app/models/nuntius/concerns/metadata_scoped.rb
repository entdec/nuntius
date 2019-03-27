# frozen_string_literal: true

module Nuntius::MetadataScoped
  extend ActiveSupport::Concern

  included do
    default_scope { instance_exec(User.current, &Nuntius.config.user_scope) }
    before_save :add_user_metadata
  end

  private

  def add_user_metadata
    instance_exec(User.current, &Nuntius.config.add_user_metadata)
  end
end
