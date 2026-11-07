# frozen_string_literal: true

require "test_helper"

module Nuntius
  class TemplateConversionTest < ActiveSupport::TestCase
    include EmailDesignHelper

    def old_template(html)
      Template.create!(description: "Old", klass: "Custom", event: "order#placed", transport: "mail", to: "{{ order.email }}", subject: "Order {{ order.number }}", html: html, old_layout: nuntius_old_layouts(:one))
    end

    def body_html(html)
      TemplateConversion.new(Template.new(html: html), nil).body_html
    end

    test "HTML stays as it is, with closed tags and its Liquid" do
      html = body_html(%(<table width="600"><tr><td>Hi {{ name }}<br><a href="{{ order.url }}">Order</a></td></tr></table>))

      # Markdown indents HTML blocks, as it does when sending now
      assert_equal %(<table width="600"><tr><td>Hi {{ name }}<br /><a href="{{ order.url }}">Order</a></td></tr></table>), html.gsub(/>\s+</, "><")
    end

    test "plain text becomes paragraphs, as Markdown sends it now" do
      assert_equal "<p>{{ name }} cancelled.</p>\n\n<p>Kind regards</p>", body_html("{{ name }} cancelled.\n\nKind regards")
    end

    test "lines with only Liquid tags are no paragraphs" do
      html = body_html("{% assign done_count = 0 %}\n{% assign open_count = 1 %}\n\nDone: {{ done_count }}")

      assert_equal "{% assign done_count = 0 %}\n{% assign open_count = 1 %}\n\n<p>Done: {{ done_count }}</p>", html
    end

    test "Liquid between attributes stays where it is" do
      html = body_html(%(<td {% if wide %}width="600"{% endif %}>Hi</td>))

      assert_includes html, "{% if wide %}"
      assert_includes html, "{% endif %}"
      assert_not_includes html, %({% if wide %}="")
    end

    test "Liquid right against an attribute stays HTML" do
      html = body_html(%(<td><span {% if late > 0 %}style="color: red"{% endif %}>{{ late }}</span></td>))

      assert_match %r{<span {% if late > 0 %}\s*style="color: red"\s*{% endif %}\s*>{{ late }}</span>}, html
    end

    test "Liquid comparisons are written without <, which MJML does not take" do
      assert_includes body_html("{% if days <= 30 and count > 0 %}x{% endif %}"), "{% if 30 >= days and count > 0 %}x{% endif %}"
      assert_includes body_html("{% if a < 'b' %}x{% endif %}"), "{% if 'b' > a %}"
    end

    test "Liquid inside an attribute uses single quotes" do
      html = body_html(%(<a href="{{ host }}{%helper "contract_path" contract.id%}">Sign</a>))

      assert_includes html, %(<a href="{{ host }}{%helper 'contract_path' contract.id%}">Sign</a>)
    end

    test "Liquid comparing inside an HTML tag is refused, with what to change" do
      template = old_template(%(<span {% if late > 0 %}style="color: red"{% endif %}>{{ late }}</span>))

      assert_not TemplateConversion.new(template, create_layout).convert
      assert_match "{% if late > 0 %}", template.errors[:base].sole
      assert_not template.reload.email_design?
    end

    test "converting puts the body into the layout, and keeps what it was" do
      layout = create_layout
      template = old_template("<p>Your order {{ order.number }}</p>")

      assert TemplateConversion.new(template, layout).convert

      template.reload
      assert template.email_design?
      assert_nil template.old_layout
      assert_equal layout, template.layout
      assert_equal "raw", template.json.sole["type"]
      assert_includes template.html, "Your order {{ order.number }}"
      assert_includes template.html, "ACME"
      assert_equal "Order {{ order.number }}", template.subject
      assert_equal "<p>Your order {{ order.number }}</p>", template.converted_from["html"]
      assert_equal nuntius_old_layouts(:one).id, template.converted_from["old_layout_id"]
    end

    test "the converted template opens in the editor with its body in the Content block" do
      layout = create_layout
      template = old_template("<p>Mine</p>")
      TemplateConversion.new(template, layout).convert

      nodes = EmailDesign.content_nodes(template.reload.editor_document)
      assert_equal "<p>Mine</p>", nodes.sole.dig("data", "html")
    end

    test "without a layout nothing changes" do
      template = old_template("<p>Mine</p>")

      assert_not TemplateConversion.new(template, nil).convert
      assert_equal ["Choose a layout"], template.errors[:base]
      assert_equal nuntius_old_layouts(:one), template.reload.old_layout
      assert_not template.email_design?
    end

    test "a template already in the email editor is not converted again" do
      layout = create_layout
      template = old_template("<p>Mine</p>")
      TemplateConversion.new(template, layout).convert

      assert_not TemplateConversion.new(template.reload, layout).convert
    end
  end
end
