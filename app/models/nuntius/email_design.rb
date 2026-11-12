# frozen_string_literal: true

module Nuntius
  # Puts a template's or campaign's own content into its layout, as MJML.
  #
  # The layout's Content block marks its place in the MJML with two comments:
  #
  #   <mj-raw><!-- nuntius:content --></mj-raw>
  #   ... the blocks inside the Content block ...
  #   <mj-raw><!-- /nuntius:content --></mj-raw>
  #
  # A template stores the whole email as MJML. When its layout changes, the
  # part between the markers is taken out of the template's MJML and put into
  # the layout's new MJML, with the template's subject and preview text in its
  # <mj-head>.
  module EmailDesign
    CONTENT_START = "<mj-raw><!-- nuntius:content --></mj-raw>"
    CONTENT_END = "<mj-raw><!-- /nuntius:content --></mj-raw>"
    CONTENT = /#{Regexp.escape(CONTENT_START)}(.*?)#{Regexp.escape(CONTENT_END)}/m
    LIQUID = /{%.*?%}|{{.*?}}/m
    LIQUID_PARTS = /(#{LIQUID})/m
    ONLY_LIQUID = /\A#{LIQUID}\z/m

    class Error < StandardError; end

    module_function

    # The MJML between the markers.
    def content_of(mjml)
      matches = mjml.to_s.scan(CONTENT)
      raise Error, "The MJML has #{matches.size} Content blocks, it needs exactly one" unless matches.size == 1

      matches.first.first
    end

    # The layout's MJML with this content in its Content block, and this
    # subject and preview text in its <mj-head>.
    def merge(layout_mjml, content, subject: nil, preview_text: nil)
      content_of(layout_mjml)
      mjml = layout_mjml.sub(CONTENT) { "#{CONTENT_START}#{content}#{CONTENT_END}" }
      mjml = mjml.gsub(%r{\s*<mj-title>.*?</mj-title>|\s*<mj-preview>.*?</mj-preview>}m, "")
      head = []
      head << "<mj-title>#{escape_text(subject)}</mj-title>" if subject.present?
      head << "<mj-preview>#{escape_text(preview_text)}</mj-preview>" if preview_text.present?
      return mjml if head.empty?

      raise Error, "The layout's MJML has no <mj-head>" unless mjml.include?("<mj-head>")
      mjml.sub("<mj-head>") { "<mj-head>\n    #{head.join("\n    ")}" }
    end

    # Like the editor's escaping: <, > and & become entities, Liquid stays as it is.
    def escape_text(text)
      parts = text.to_s.split(LIQUID_PARTS)
      parts.map { |part| part.match?(ONLY_LIQUID) ? part : part.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;") }.join
    end

    # The children of the document's Content block, nil when it has none.
    def content_nodes(document)
      content_node(document)&.fetch("children", [])
    end

    # The layout's document with these nodes in its Content block, and this
    # subject and preview text on its root.
    # data: more of the root's data, such as a template's From and To
    def document_with(layout_document, nodes, subject: nil, preview_text: nil, data: {})
      document = layout_document.deep_dup
      content_node(document)["children"] = nodes || []
      document["data"] = (document["data"] || {}).merge("subject" => subject.to_s, "preheader" => preview_text.to_s).merge(data)
      document
    end

    def content_node(node)
      return nil unless node.is_a?(Hash)
      return node if node["type"] == "content"

      Array(node["children"]).each do |child|
        found = content_node(child)
        return found if found
      end
      nil
    end
  end
end
