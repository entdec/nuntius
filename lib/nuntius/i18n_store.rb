# frozen_string_literal: true

require "i18n/core_ext/hash"

module Nuntius
  begin
    require "oj"
    class JSON
      class << self
        def encode(value)
          Oj::Rails.encode(value)
        end

        def decode(value)
          Oj.load(value)
        end
      end
    end
  rescue LoadError
    require "active_support/json"
    JSON = ActiveSupport::JSON
  end

  # The translations of a template's or campaign's account (its locales) for
  # Liquidum's `t` filter, as a store for I18n::Backend::KeyValue
  # ({"en.greeting" => "\"Hello\""}). Configure Liquidum with:
  #
  #   Liquidum.setup do |config|
  #     config.i18n_store = ->(context) { Nuntius::I18nStore.backend(context) }
  #     config.translation_scope = ->(context) { Nuntius::I18nStore.translation_scope(context) }
  #   end
  class I18nStore
    # Looks a key up from its scope towards the root
    class Backend < I18n::Backend::KeyValue
      include I18n::Backend::Cascade
    end

    class << self
      # The account's locales of the template or campaign being rendered, then
      # the app's own translations
      def backend(context)
        owner = owner(context)
        return I18n.backend unless owner

        I18n::Backend::Chain.new(Backend.new(new(owner)), I18n.backend)
      end

      # The scope of keys that start with a dot
      def translation_scope(context)
        owner(context)&.translation_scope
      end

      private

      def owner(context)
        context.registers["template"] || context.registers["campaign"]
      end
    end

    def initialize(owner)
      @owner = owner
    end

    def keys
      translations.keys
    end

    def [](key)
      translations[key]
    end

    def []=(key, value)
      # NOOP
    end

    private

    def translations
      @translations ||= Nuntius::Locale.owned_by(@owner.account_id).in_order.each_with_object({}) do |locale, result|
        result.merge!(flat_hash(locale.data).transform_values { |value| JSON.encode(value) })
      end
    end

    def flat_hash(hash = {})
      (hash || {}).reduce({}) do |a, (k, v)|
        tmp = v.is_a?(Hash) ? flat_hash(v).transform_keys { |k2| "#{k}.#{k2}" } : {k => v}
        a.merge(tmp)
      end
    end
  end
end
