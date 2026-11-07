# frozen_string_literal: true

module Nuntius
  # The variables an email design's Liquid can use, for the email editor's
  # suggestions: the roots it's rendered with, as a template's or campaign's
  # variable_roots, for Liquidum::Variables. The editor only gets them when the
  # host app mounts Liquidum (see the email editor partial).
  module Variables
    module_function

    # A model's drop under its name in Liquid, as messengers name it:
    # "Order" → {"order" => OrderDrop}. Nothing for a class without a drop.
    def for_class(name)
      model = name.to_s.safe_constantize
      return {} unless model.is_a?(Class)

      model = model.base_class if model.respond_to?(:base_class)
      drop = "#{model.name}Drop".safe_constantize
      drop ? {model.name.demodulize.underscore => drop} : {}
    end

    # The URL of Liquidum's variables endpoint for these roots, signed, or nil
    # when the host app hasn't mounted Liquidum. `routes` is the view (with the
    # host's mounted engines' route helpers).
    def url(routes, roots)
      return unless routes.respond_to?(:liquidum)

      routes.liquidum.variables_path(roots: Liquidum::Variables.new(roots).token)
    end
  end
end
