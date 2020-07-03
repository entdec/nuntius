# frozen_string_literal: true

Liquor.setup do |config|
  config.i18n_store = lambda do |context, block|
    Nuntius.i18n_store.with(context.registers['template'], &block)
  end
end
