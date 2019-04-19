# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  class DashboardController < ApplicationAdminController
    add_breadcrumb(I18n.t('nuntius.breadcrumbs.dashboard'), :root_path) if defined? add_breadcrumb

    def show
      @messages = Nuntius::Message.order(created_at: :desc).limit(10)
    end
  end
end
