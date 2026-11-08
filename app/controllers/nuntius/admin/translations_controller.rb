# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    # The translations a template, campaign or layout uses through Liquid's t
    # filter, for the email editor (TessEdit's translationsUrl) and the
    # Translations tab: what they say in each language, and saving one (see
    # Translations).
    class TranslationsController < ApplicationAdminController
      OWNERS = {"layout" => "Nuntius::Layout", "template" => "Nuntius::Template", "campaign" => "Nuntius::Campaign"}.freeze

      before_action :set_translations

      # The keys asked for and the ones to suggest
      def index
        suggestions = @translations.suggestions
        keys = params[:keys].to_s.split(",").map(&:strip).reject(&:blank?) | suggestions
        render json: {
          locales: @translations.locales,
          translations: keys.index_with { |key| translation_json(key) },
          suggestions: suggestions
        }
      end

      def update
        @translations.save(params.require(:key), params.require(:locale), params[:value].to_s)
        render json: {key: params[:key], translation: translation_json(params[:key])}
      rescue Translations::Error, ActiveRecord::RecordInvalid => error
        render json: {errors: [error.message]}, status: :unprocessable_content
      end

      private

      def set_translations
        record = OWNERS.fetch(params[:owner]).constantize.visible.find(params[:id])
        @translations = Translations.new(record)
      end

      def translation_json(key)
        @translations.lookup(key).transform_values do |text|
          next unless text

          {value: text.value, source: text.source, url: (edit_admin_locale_path(text.locale_record) if text.locale_record)}
        end
      end
    end
  end
end
