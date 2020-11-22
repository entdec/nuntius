# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  class DashboardController < ApplicationAdminController
    def show
      @templates = Nuntius::Template.visible.all
      @messages = Nuntius::Message.visible.order(created_at: :desc).limit(10)
    end
  end
end
