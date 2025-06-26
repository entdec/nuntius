# frozen_string_literal: true

Liquidum.setup do |config|
  config.i18n_store = ->(context) { Nuntius.i18n_store.with(context.registers["template"]) }
end
