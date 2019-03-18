# frozen_string_literal: true

require 'delegate'

# http://nithinbekal.com/posts/rails-presenters/
class ApplicationPresenter < SimpleDelegator
  delegate :t, to: I18n

  # Returns reference to the object we're decorating
  def model
    __getobj__
  end

  def route
    Rails.application.routes.url_helpers
  end

  # Provide access to view/helpers
  def h
    @h ||= ActionView::Base.new
  end

  class << self
    def model(model_alias)
      alias_method(model_alias, :model)
    end
  end
end
