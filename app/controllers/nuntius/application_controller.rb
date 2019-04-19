# frozen_string_literal: true

module Nuntius
  class ApplicationController < Nuntius.config.base_controller.constantize
    protect_from_forgery with: :exception
    add_breadcrumb(I18n.t('nuntius.breadcrumbs.nuntius'), :root_url) if defined? add_breadcrumb
  end
end
