# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # The dummy app has no users: the admin is the first account's
  before_action { Current.account ||= Account.order(:name).first }
end
