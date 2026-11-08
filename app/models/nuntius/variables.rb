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

    # For conditions (EntDec::Conditions::Component): a variable's labels from
    # the root ("User › Name") and its type, from its path; nil when unknown
    def describer(roots)
      variables = Liquidum::Variables.new(roots)
      at = Hash.new { |cache, path| cache[path] = variables.at(path) }

      lambda do |path|
        names = path.to_s.split(".")
        found = names.each_with_index.map do |name, index|
          at[names[0...index].join(".")]&.find { |variable| variable.name == name } or break
        end
        [found.map(&:label).join(" › "), found.last.type] if found&.any?
      end
    end
  end
end
