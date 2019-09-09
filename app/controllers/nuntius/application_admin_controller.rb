# frozen_string_literal: true

require_dependency 'nuntius/application_controller'

module Nuntius
  class ApplicationAdminController < ApplicationController
    include Concerns::Respond
    include Nuntius.config.admin_authentication_module.constantize if Nuntius.config.admin_authentication_module
  end
end
