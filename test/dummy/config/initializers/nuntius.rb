# frozen_string_literal: true

Nuntius.setup do |config|
  config.base_controller = '::ApplicationController'
  config.logger = Rails.logger
end
