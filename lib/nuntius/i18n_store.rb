# frozen_string_literal: true

require 'i18n/core_ext/hash'

module Nuntius
  begin
    require 'oj'
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
    require 'active_support/json'
    JSON = ActiveSupport::JSON
  end

  class I18nStore
    attr_reader :template

    def initialize; end

    def keys
      return [] unless template

      result = []
      locales.each do |locale|
        result += flat_hash(locale.data).keys
      end
      result
    end

    def [](key)
      return unless template

      result = {}
      locales.each do |locale|
        hash = flat_hash(locale.data).transform_values { |v| JSON.encode(v) }
        result.merge! hash
      end
      result[key]
    end

    def []=(key, value)
      # NOOP
    end

    def with(template)
      with_custom_backend do
        @template = template
        yield(template)
        @template = nil
      end
    end

    private

    def with_custom_backend
      @old_backend = I18n.backend
      I18n.backend = I18n::Backend::Chain.new(custom_i18n_backend, I18n.backend)

      yield

      I18n.backend = @old_backend
      @old_backend = nil
    end

    def locales
      Nuntius::Locale.all
    end

    def flat_hash(hash)
      hash.reduce({}) do |a, (k, v)|
        tmp = v.is_a?(Hash) ? flat_hash(v).map { |k2, v2| ["#{k}.#{k2}", v2] }.to_h : { k => v }
        a.merge(tmp)
      end
    end

    # Yield our own custom backend
    def custom_i18n_backend
      return @custom_i18n_backend if @custom_i18n_backend

      @custom_i18n_backend = I18n::Backend::KeyValue.new(Nuntius.i18n_store)
      @custom_i18n_backend.class.send(:include, I18n::Backend::Cascade)

      @custom_i18n_backend
    end
  end
end
