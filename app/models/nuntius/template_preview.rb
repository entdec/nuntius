# frozen_string_literal: true

module Nuntius
  # A template's message as its editor previews it (SMS, Push, Teams, Slack,
  # Voice): its text and payload rendered with sample values, not with a
  # record, so no account's data shows. A variable shows as its label,
  # ‹User › First name›, or its path when Liquidum doesn't know it.
  class TemplatePreview
    def initialize(template, locale: I18n.locale)
      @template = template
      @locale = locale
    end

    # {text:, payload:, errors:}, with the payload as the provider gets it
    def to_h
      errors = []
      payload = begin
        render(:payload) if @template.payload.present?
      rescue Psych::Exception => e
        errors << "The payload isn't valid YAML once rendered: #{e.message}"
        nil
      end
      {text: render(:text).to_s, payload: payload, errors: errors}
    end

    private

    # As it renders for sending (Template#render, private there)
    def render(attribute)
      @template.send(:render, attribute, assigns, @locale)
    end

    # A sample for each of the class's roots, and for any other variable the
    # Liquid uses, so a misspelled or another class's variable shows too
    def assigns
      @assigns ||= begin
        roots = @template.variable_roots || {}
        describe = Variables.describer(roots)
        (roots.keys.map(&:to_s) | used_names).to_h { |name| [name, SampleDrop.new(name, describe)] }
      end
    end

    def used_names
      [@template.text, @template.payload].compact_blank.flat_map do |source|
        root = ::Liquid::Template.parse(source).root
        ::Liquid::ParseTreeVisitor.for(root).add_callback_for(::Liquid::VariableLookup) { |node| node.name }.visit.flatten
      rescue ::Liquid::Error
        []
      end.grep(String).uniq
    end

    # Any variable below it is another sample; a collection has one of them.
    class SampleDrop < ::Liquid::Drop
      include Enumerable

      def initialize(path, describe)
        @path = path
        @describe = describe
      end

      def liquid_method_missing(name)
        SampleDrop.new("#{@path}.#{name}", @describe)
      end

      def each
        yield self
      end

      def size
        1
      end

      def to_s
        label, = @describe.call(@path)
        "‹#{label || @path}›"
      end
    end
  end
end
