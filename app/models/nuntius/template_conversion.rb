# frozen_string_literal: true

module Nuntius
  # Converts a template with an old layout into the email editor: its body
  # goes into one HTML block in the Content block of a new layout.
  #
  # The body becomes HTML the way it is sent now (Markdown), with its Liquid
  # left as it is, and is cleaned up so MJML takes it (closed tags, quoted
  # attributes). Liquid that MJML would not take is written another way
  # that means the same: no < in tags, single quotes inside attributes. The
  # old layout and body are kept in converted_from.
  class TemplateConversion
    TOKEN = /nuntiusliquid(\d+)x/
    TOKEN_ATTRIBUTE = /(nuntiusliquid\d+x)=""/
    HTML_TAG = /<[a-zA-Z][^<>]*>/
    QUOTED_OR_TOKEN = /("[^"]*"|'[^']*')|(nuntiusliquid\d+x)/
    ONLY_TAGS = /\A(?:\s*nuntiusliquid\d+x)+\s*\z/
    OPERAND = /"[^"]*"|'[^']*'|[^\s<>=!]+/
    # MJML takes no < in text: a < b becomes b > a
    LESS_THAN = /(#{OPERAND})\s*<(=?)\s*(#{OPERAND})/

    attr_reader :template, :layout

    def initialize(template, layout)
      @template = template
      @layout = layout
    end

    # Saves the converted template; false (with errors on the template, which
    # is left as it was) when it can't be converted
    def convert
      return failure("This template already uses the email editor") if template.email_design?
      return failure("Only templates with an old layout are converted") unless template.old_layout
      return failure("Choose a layout") unless layout

      problem = unconvertible_liquid
      return failure("Liquid inside an HTML tag compares with < or >, which MJML can't take: #{problem}. Put the condition around the tag instead, then convert.") if problem

      original = {"old_layout_id" => template.old_layout_id, "old_layout_name" => template.old_layout.name, "html" => template.html, "converted_at" => Time.current.iso8601}
      html = body_html
      template.layout = layout
      template.old_layout = nil
      template.converted_from = original
      template.assign_content([html_node(html)], "<mj-raw>#{html}</mj-raw>")
      return true if template.save(context: :admin)

      errors = template.errors.full_messages
      template.restore_attributes
      template.association(:layout).reset
      template.association(:old_layout).reset
      errors.each { |message| template.errors.add(:base, message) }
      false
    end

    # The body as HTML, with its Liquid as it was
    def body_html
      liquid = []
      source = template.html.to_s.gsub(EmailDesign::LIQUID) do |part|
        liquid << part
        "nuntiusliquid#{liquid.size - 1}x"
      end
      # Liquid between attributes ({% if %}style="…"{% endif %}) gets spaces
      # around it, or Markdown takes the tag for text
      source = source.gsub(HTML_TAG) { |tag| tag.gsub(QUOTED_OR_TOKEN) { $1 || " #{$2} " } }

      fragment = Nokogiri::HTML4::DocumentFragment.parse(Tilt["markdown"].new { source }.render)
      # A line with only Liquid tags ({% if %}, {% assign %}) is no paragraph
      fragment.css("p").each do |paragraph|
        next unless paragraph.element_children.empty? && paragraph.text.match?(ONLY_TAGS)
        next unless paragraph.text.scan(TOKEN).flatten.all? { |index| liquid[index.to_i].start_with?("{%") }

        paragraph.replace(paragraph.children)
      end

      in_attributes = fragment.xpath(".//@*").flat_map { |attribute| attribute.value.scan(TOKEN).flatten }.map(&:to_i)
      fragment.to_xhtml(encoding: "UTF-8").strip
        .gsub(TOKEN_ATTRIBUTE, '\1') # Liquid between attributes
        .gsub(TOKEN) do
          index = Regexp.last_match(1).to_i
          part = liquid[index]
          part = part.gsub(LESS_THAN) { "#{$3} >#{$2} #{$1}" } if part.start_with?("{%")
          part = part.tr('"', "'") if in_attributes.include?(index) && !part.include?("'")
          part
        end
    end

    # Liquid with < or > inside an HTML tag (<span {% if a > 0 %}…>): that
    # ends the tag for MJML, and there is no way to write it without them
    def unconvertible_liquid
      liquid = []
      source = template.html.to_s.gsub(EmailDesign::LIQUID) do |part|
        liquid << part
        "nuntiusliquid#{liquid.size - 1}x"
      end
      source.scan(HTML_TAG).join.scan(TOKEN).flatten.map { |index| liquid[index.to_i] }.find { |part| part.match?(/[<>]/) }
    end

    private

    def html_node(html)
      {"id" => "b#{SecureRandom.alphanumeric(10).downcase}", "type" => "raw", "attributes" => {}, "data" => {"html" => html}, "children" => []}
    end

    def failure(message)
      template.errors.add(:base, message)
      false
    end
  end
end
