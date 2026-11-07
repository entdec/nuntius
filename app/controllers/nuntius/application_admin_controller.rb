# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class ApplicationAdminController < ApplicationController
    include Nuntius.config.admin_authentication_module.constantize if Nuntius.config.admin_authentication_module
    # The Media tabs show previews of images, whose URLs need the request's host (Disk service)
    include ActiveStorage::SetCurrent

    layout Nuntius.config.admin_layout
  end
end
