# frozen_string_literal: true

# A layout as the email editor exports it: a header and footer around a
# Content block with example content.
module EmailDesignHelper
  def layout_mjml(header: "ACME", example: "Example content")
    <<~MJML
      <mjml>
        <mj-head>
          <mj-title>Layout title</mj-title>
          <mj-breakpoint width="480px" />
        </mj-head>
        <mj-body>
          <mj-section><mj-column><mj-text>#{header}</mj-text></mj-column></mj-section>
          #{content_mjml(example)}
          <mj-section><mj-column><mj-text>ACME Store · Main Street 1 <a href="{{ subscriber_url }}">Manage your subscription</a></mj-text></mj-column></mj-section>
        </mj-body>
      </mjml>
    MJML
  end

  def content_mjml(text)
    "#{Nuntius::EmailDesign::CONTENT_START}\n<mj-section><mj-column><mj-text>#{text}</mj-text></mj-column></mj-section>\n#{Nuntius::EmailDesign::CONTENT_END}"
  end

  def layout_json(example: "Example content")
    {
      "id" => "broot", "type" => "email", "attributes" => {}, "data" => {"subject" => "", "preheader" => ""},
      "children" => [
        {"id" => "bheader", "type" => "section", "attributes" => {}, "data" => {}, "children" => []},
        {"id" => "bcontent", "type" => "content", "attributes" => {}, "data" => {}, "children" => [text_node("bexample", example)]}
      ]
    }
  end

  def text_node(id, text)
    {"id" => id, "type" => "text", "attributes" => {}, "data" => {"content" => {"type" => "doc", "content" => [{"type" => "paragraph", "content" => [{"type" => "text", "text" => text}]}]}}, "children" => []}
  end

  def create_layout(**options)
    Nuntius::Layout.create!(name: "ACME", json: layout_json, mjml: layout_mjml(**options))
  end

  # What the editor submits for a template in this layout.
  def submitted_design(layout, text:, subject: "Order {{ order.number }}", preview_text: "Thanks", header: "ACME")
    document = Nuntius::EmailDesign.document_with(layout.json, [text_node("bmine", text)], subject: subject, preview_text: preview_text)
    {document: document.to_json, mjml: layout_mjml(header: header, example: text)}
  end
end
