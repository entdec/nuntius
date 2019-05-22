# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  class DashboardController < ApplicationAdminController
    add_breadcrumb(I18n.t('nuntius.breadcrumbs.dashboard'), :root_path) if defined? add_breadcrumb

    def show
      @templates = Nuntius::Template.visible.all
      @messages = Nuntius::Message.where(template: @templates).order(created_at: :desc).limit(10)
    end
  end
end
