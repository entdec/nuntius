# frozen_string_literal: true

require_dependency 'nuntius/application_controller'
require_dependency 'concerns/maintenance_standards'

module Nuntius
  class ApplicationAdminController < ApplicationController
    include MaintenanceStandards
    include Nuntius.config.admin_authentication_module.constantize if Nuntius.config.admin_authentication_module
  end
end
