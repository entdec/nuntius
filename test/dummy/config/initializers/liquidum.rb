# frozen_string_literal: true

Liquidum.setup do |config|
  config.i18n_store = ->(context) { Nuntius::I18nStore.backend(context) }
  config.translation_scope = ->(context) { Nuntius::I18nStore.translation_scope(context) }
end
