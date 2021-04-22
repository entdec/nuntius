# frozen_string_literal: true

module Nuntius
  class ApplicationController < Nuntius.config.base_controller.constantize
    self.responder = Auxilium::Responder
    respond_to :html

    protect_from_forgery with: :exception

    layout Nuntius.config.layout
  end
end
