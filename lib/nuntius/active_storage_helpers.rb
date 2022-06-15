# frozen_string_literal: true

module Nuntius::ActiveStorageHelpers
  extend ActiveSupport::Concern
  included do
    has_one_attached :content, service: :nuntius
  end
end
