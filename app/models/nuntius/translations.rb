# frozen_string_literal: true

module Nuntius
  # The translations a template, campaign or layout uses through Liquid's t
  # filter ({{ '.greeting' | t }}), kept in its account's locales (see
  # I18nStore). A key starting with a dot is in its translation_scope, and
  # like the filter it's looked up from there towards the root: '.greeting'
  # in "basic.user.activate" is basic.user.activate.greeting, then
  # basic.user.greeting, basic.greeting and greeting. The app's own
  # translations come after the account's.
  #
  # The email editor shows and edits them (Admin::TranslationsController),
  # and so does the Translations tab.
  class Translations
    # A t filter on a quoted key
    CALL = /\{\{-?\s*(["'])([^"'{}|]+?)\1\s*\|\s*t(?:ranslate)?\b/
    KEY = /\A\.?[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)*\z/
    # Where an owner's Liquid can have them
    FIELDS = %i[from to subject preview_text html text payload mjml].freeze

    # A text in a language: value, where it's kept (the Locale and the path
    # in it, none for the app's own) and the full key it was found at
    Text = Struct.new(:value, :locale_record, :path) do
      def source
        if locale_record
          I18n.t("nuntius.translations.source", name: locale_record.key, key: path)
        else
          I18n.t("nuntius.translations.app_source", key: path)
        end
      end
    end

    class Error < StandardError; end

    attr_reader :owner

    # Moves an account's translations in one scope to another, in every
    # locale and language: when a template's scope changes, or a layout's
    # name. Ones already in the new scope stay as they are.
    def self.move(account_id, from, to)
      from = from.to_s.split(".")
      to = to.to_s.split(".")
      return if from.empty? || to.empty? || from == to || to.first(from.size) == from

      Nuntius::Locale.owned_by(account_id).in_order.each do |record|
        data = (record.data || {}).deep_dup
        moved = data.values.select { |translations| translations.is_a?(Hash) }.map { |translations| move_in(translations, from, to) }
        next unless moved.any?

        record.data = data
        record.save!(validate: false)
      end
    end

    def self.move_in(translations, from, to)
      *parents, last = from
      parent = parents.inject(translations) { |level, segment| level.is_a?(Hash) ? level[segment] : nil }
      return false unless parent.is_a?(Hash) && parent[last].is_a?(Hash)

      *target_parents, target_last = to
      target = target_parents.inject(translations) do |level, segment|
        return false unless level[segment].nil? || level[segment].is_a?(Hash)
        level[segment] ||= {}
      end
      return false unless target[target_last].nil? || target[target_last].is_a?(Hash)

      target[target_last] = parent.delete(last).deep_merge(target[target_last] || {})
      # Removes the levels it leaves empty
      parents.size.downto(1) do |depth|
        level = parents.first(depth).inject(translations) { |hash, segment| hash[segment] }
        break unless level == {}

        parents.first(depth - 1).inject(translations) { |hash, segment| hash[segment] }.delete(parents[depth - 1])
      end
      true
    end
    private_class_method :move_in

    def initialize(owner)
      @owner = owner
    end

    # The app's languages and those in the account's locales, the app's
    # default first
    def locales
      @locales ||= begin
        found = (I18n.available_locales.map(&:to_s) + records.flat_map { |record| (record.data || {}).keys.map(&:to_s) }).uniq
        default = I18n.default_locale.to_s
        found.sort_by { |locale| [(locale == default) ? 0 : 1, locale] }
      end
    end

    # The keys its Liquid translates, in order of appearance
    def keys
      FIELDS.select { |field| owner.respond_to?(field) }
        .flat_map { |field| owner.public_send(field).to_s.scan(CALL).map(&:last) }
        .map(&:strip).uniq
    end

    # What a key says in each language: {"en" => Text, "nl" => nil}
    def lookup(key)
      locales.index_with { |locale| text(key, locale) }
    end

    def text(key, locale)
      candidates(key).each do |path|
        record = records.rfind { |record| string?(dig(record.data, locale, path)) }
        return Text.new(value: dig(record.data, locale, path), locale_record: record, path: path) if record
      end
      app_text(key, locale)
    end

    # The keys starting with a dot that its Liquid can use: those in its own
    # scope, and those right in the scopes above it (the filter doesn't find
    # deeper ones there)
    def suggestions
      own = scope_segments
      records.flat_map { |record| flat_keys(record.data) }.filter_map { |(_locale, path)|
        segments = path.split(".")
        if segments.size > own.size && segments.first(own.size) == own
          ".#{segments.drop(own.size).join(".")}"
        elsif segments.size <= own.size && segments[0..-2] == own.first(segments.size - 1)
          ".#{segments.last}"
        end
      }.uniq.sort
    end

    # Saves a key's text in a language, where it's defined in that language,
    # or else next to its other languages (in its own scope when it has
    # none) in the account's locale named after the language. An empty text
    # removes it. Returns lookup(key).
    def save(key, locale, value)
      key = key.to_s.strip
      locale = locale.to_s
      raise Error, I18n.t("nuntius.translations.invalid_key", key: key) unless KEY.match?(key)
      raise Error, I18n.t("nuntius.translations.invalid_locale", locale: locale) unless locales.include?(locale)

      current = text(key, locale)
      if current&.locale_record
        write(current.locale_record, locale, current.path, value.presence)
      elsif value.present?
        write(locale_record(locale), locale, home(key), value)
      end
      @records = nil
      lookup(key)
    end

    private

    def account_id
      owner.account_id
    end

    # Later ones win, as in I18nStore
    def records
      @records ||= Nuntius::Locale.owned_by(account_id).in_order.to_a
    end

    def scope_segments
      owner.translation_scope.to_s.split(".").reject(&:blank?)
    end

    # The full keys the filter tries, in order (I18n::Backend::Cascade with
    # skip_root: false)
    def candidates(key)
      segments = key.start_with?(".") ? scope_segments + key.delete_prefix(".").split(".") : key.split(".")
      leaf = segments.pop
      segments.size.downto(0).map { |size| (segments.first(size) + [leaf]).join(".") }
    end

    def app_text(key, locale)
      path = candidates(key).first
      value = I18n.t(path, locale: locale, default: nil)
      Text.new(value: value, path: path) if string?(value)
    rescue I18n::ArgumentError
      nil
    end

    # Where a new text goes: next to its other languages, or in its own scope
    def home(key)
      candidates(key).find { |path| locales.any? { |other| records.any? { |record| string?(dig(record.data, other, path)) } } } || candidates(key).first
    end

    def locale_record(locale)
      records.rfind { |record| record.key == locale } ||
        Nuntius::Locale.new(account_id: account_id, key: locale, data: {locale => {}})
    end

    def write(record, locale, path, value)
      data = (record.data || {}).deep_dup
      *parents, leaf = [locale, *path.split(".")]
      hash = parents.inject(data) do |level, segment|
        level[segment] = {} if level[segment].nil? && value
        raise Error, I18n.t("nuntius.translations.taken", key: path) unless level[segment].nil? || level[segment].is_a?(Hash)
        level[segment] || {}
      end
      raise Error, I18n.t("nuntius.translations.taken", key: path) if hash[leaf].is_a?(Hash)

      value ? hash[leaf] = value : hash.delete(leaf)
      record.data = data
      record.save!
    end

    # Hash#dig, but nil where a text is in the way
    def dig(data, locale, path)
      [locale, *path.split(".")].inject(data) { |level, segment| level.is_a?(Hash) ? level[segment] : nil }
    end

    def string?(value)
      value.is_a?(String)
    end

    def flat_keys(data, prefix = [])
      (data || {}).flat_map do |key, value|
        next [] unless value.is_a?(Hash) || value.is_a?(String)
        next [[prefix.first, (prefix.drop(1) + [key]).join(".")]] if value.is_a?(String) && prefix.any?

        value.is_a?(Hash) ? flat_keys(value, prefix + [key.to_s]) : []
      end
    end
  end
end
