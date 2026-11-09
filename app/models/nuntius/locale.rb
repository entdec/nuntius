# frozen_string_literal: true

module Nuntius
  # An account's translations for the t filter (see I18nStore and
  # Translations). Its data starts with the languages: {"nl" => {"greeting"
  # => "Hoi"}}. Its key is a name, unique in the account; a locale named
  # after a language is where new translations in that language go.
  class Locale < ApplicationRecord
    include Nuntius::Concerns::Owned
    include Nuntius::Concerns::Yamlify

    # en, nl, pt-BR, zh-Hant
    LANGUAGE = /\A[a-z]{2,3}([-_][A-Za-z0-9]{2,8})*\z/

    yamlify :data

    validates :key, presence: true, uniqueness: {scope: :account_id}
    validate :data_by_language

    # The order their translations merge in, later ones winning (see I18nStore)
    scope :in_order, -> { order(:created_at, :id) }

    private

    def data_by_language
      return if data.nil?
      return errors.add(:data, :not_by_language) unless data.is_a?(Hash)

      data.each do |language, translations|
        errors.add(:data, :not_a_language, key: language) unless LANGUAGE.match?(language.to_s)
        errors.add(:data, :not_by_key, key: language) unless translations.nil? || translations.is_a?(Hash)
      end
    end
  end
end
