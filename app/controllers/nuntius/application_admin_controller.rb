# frozen_string_literal: true

require_dependency 'nuntius/application_controller'

module Nuntius
  class ApplicationAdminController < ApplicationController
    include Nuntius.config.admin_authentication_module.constantize if Nuntius.config.admin_authentication_module

    layout Nuntius.config.admin_layout
  end
end
