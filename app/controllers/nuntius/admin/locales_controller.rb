# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    class LocalesController < ApplicationAdminController
      def index
        @locales = Nuntius::Locale.visible.order(:key)
      end

      def new
        @locale = Nuntius::Locale.new
        render :edit
      end

      def create
        @locale = Nuntius::Locale.new(locale_params)
        @locale.save
        respond_with :admin, @locale
      end

      def show
        redirect_to :edit_admin_locales, status: :see_other
      end

      def edit
        @locale = Nuntius::Locale.visible.find(params[:id])
      end

      def update
        @locale = Nuntius::Locale.visible.find(params[:id])
        @locale.update(locale_params)
        respond_with :admin, @locale
      end

      private

      def set_objects; end

      def locale_params
        params.require(:locale).permit(:key, :data, :metadata).tap do |w|
          w[:data] = YAML.safe_load(params[:locale][:data])
          w[:metadata] = YAML.safe_load(params[:locale][:metadata])
        end
      end
    end
  end
end
