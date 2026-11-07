# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class ApplicationAdminController < ApplicationController
    include Nuntius.config.admin_authentication_module.constantize if Nuntius.config.admin_authentication_module
    # The Media tabs show previews of images, whose URLs need the request's host (Disk service)
    include ActiveStorage::SetCurrent

    layout Nuntius.config.admin_layout
    helper_method :image_url_options

    # A record that doesn't save shows its form again (new renders edit, there are no new views), with what was
    # filled in, and the notification (Auxilium::Responder's, with Signum for the current user) says why
    def respond_with(*resources, **options, &block)
      record = resources.last
      if record.respond_to?(:errors) && record.errors.any?
        options[:action] ||= :edit
        options[:error] ||= t("nuntius.admin.not_saved", resource: record.model_name.human, errors: record.errors.full_messages.to_sentence) if defined?(Signum) && respond_to?(:current_user, true)
      end
      super
    end

    private

    # Where the email editor shows uploaded images from: Nuntius' public host,
    # as the emails load them, so nothing (like the port) comes from the
    # admin's request unless there is no host
    def image_url_options
      EmailImages.url_options(Nuntius.config.host(nil)).presence || {host: request.host_with_port, protocol: request.protocol}
    end
  end
end
