# frozen_string_literal: true

module Nuntius
  class ApplicationController < Nuntius.config.base_controller.constantize
    protect_from_forgery with: :exception
  end
end
