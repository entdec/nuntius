# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class TemplatesController < ApplicationAdminController
      def index
        @templates = Template.all
      end
      def new
        @template = Template.new
        render :edit
      end
    end
  end
end
