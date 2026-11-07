# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class ApplicationAdminController < ApplicationController
    include Nuntius.config.admin_authentication_module.constantize if Nuntius.config.admin_authentication_module
    # The Media tabs show previews of images, whose URLs need the request's host (Disk service)
    include ActiveStorage::SetCurrent

    layout Nuntius.config.admin_layout
    helper_method :image_url_options

    private

    # Where the email editor shows uploaded images from: Nuntius' public host,
    # as the emails load them, so nothing (like the port) comes from the
    # admin's request unless there is no host
    def image_url_options
      EmailImages.url_options(Nuntius.config.host(nil)).presence || {host: request.host_with_port, protocol: request.protocol}
    end
  end
end
