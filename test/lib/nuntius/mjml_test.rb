# frozen_string_literal: true

require "test_helper"

module Nuntius
  # The email kit's MJML snapshots (test/javascript/mjml_snapshot_test.mjs), of
  # every tile in both modes and of the sample, compiled with MRML, as the
  # editor compiles them through TessEdit's endpoint.
  class MjmlTest < ActiveSupport::TestCase
    SNAPSHOTS = File.expand_path("../../javascript/snapshots", __dir__)

    Dir[File.join(SNAPSHOTS, "**/*.mjml")].sort.each do |file|
      test "#{file.delete_prefix("#{SNAPSHOTS}/")} compiles" do
        result = Mjml.compile(File.read(file))
        assert_empty result.errors
        assert_match(/<body/, result.html)
      end
    end

    test "Liquid in the sample survives compiling" do
      html = Mjml.compile(File.read(File.join(SNAPSHOTS, "sample.mjml"))).html
      ["{% for line in order.lines %}", "{% endfor %}", "{% if customer.orders_count == 1 %}", "{% endif %}", "{{ line.total | money }}", "href=\"{{ order.url }}\""].each do |tag|
        assert_includes html, tag
      end
    end

    test "MJML that can't be parsed gives errors and no HTML" do
      result = Mjml.compile("<mjml><mj-body><mj-text>open</mj-body></mjml>")
      assert_nil result.html
      assert_equal 1, result.errors.size
    end

    test "MJML with CRLF line endings, as browsers submit form fields, compiles" do
      sample = File.read(File.join(SNAPSHOTS, "sample.mjml"))
      result = Mjml.compile(sample.gsub("\n", "\r\n"))
      assert_empty result.errors
      assert_equal Mjml.compile(sample).html, result.html
    end

    test "is TessEdit's mjml compiler" do
      assert TessEdit.compiler?(:mjml)
      assert_equal Mjml.compile(File.read(File.join(SNAPSHOTS, "text.mjml"))).html, TessEdit.compile(:mjml, File.read(File.join(SNAPSHOTS, "text.mjml"))).html
    end

    test "a layout's MJML keeps TessEdit's content markers in mj-raw, and compiles" do
      layout = File.read(File.join(SNAPSHOTS, "content.mjml"))
      merged = TessEdit::Content.merge(layout, "<mj-text>Own</mj-text>")
      assert_includes merged, "<mj-raw><!-- tess-edit:content --></mj-raw><mj-text>Own</mj-text><mj-raw><!-- /tess-edit:content --></mj-raw>"
      assert_includes Mjml.compile(merged).html, "Own"
    end

    test "a full-width section's or wrapper's background image is on a div around its table, which Premailer leaves alone, and Outlook's in its conditional comments" do
      ["<mj-section full-width=\"full-width\" background-url=\"https://example.com/bg.jpg\"><mj-column><mj-text>In</mj-text></mj-column></mj-section>",
        "<mj-wrapper full-width=\"full-width\" background-url=\"https://example.com/bg.jpg\"><mj-section><mj-column><mj-text>In</mj-text></mj-column></mj-section></mj-wrapper>"].each do |block|
        html = Mjml.compile("<mjml><mj-body>#{block}<mj-section><mj-column><mj-text>After</mj-text></mj-column></mj-section></mj-body></mjml>").html

        assert_match(/<td><!--\[if mso \| IE\]><v:rect mso-width-percent="1000"[^>]*>.*?<!\[endif\]-->/m, html)
        assert_includes html, "<!--[if mso | IE]></v:textbox></v:rect><![endif]-->"
        visible = html.gsub(/<!--.*?-->/m, "")
        assert_no_match(/<v:/, visible)
        assert_includes visible, "In"
        assert_includes visible, "After"
        assert_equal visible.scan(/<table\b/).size, visible.scan("</table>").size
        assert_equal visible.scan(/<div\b/).size, visible.scan("</div>").size
        assert_match(%r{<div style="background:url\('https://example.com/bg.jpg'\) center top / auto repeat;[^"]*"><table [^>]*style="width:100%;"><tbody><tr><td><!--\[if mso}, html)
        assert_no_match(/<table[^>]*background/, visible)
      end
    end

    test "a full-width section's background image keeps its url through Premailer, as MailTransport sends it" do
      html = Mjml.compile("<mjml><mj-body><mj-section full-width=\"full-width\" background-url=\"https://example.com/bg.jpg\"><mj-column><mj-text>In</mj-text></mj-column></mj-section></mj-body></mjml>").html
      inlined = Premailer.new(html, with_html_string: true).to_inline_css

      assert_match(%r{<div style="[^"]*background: url\('https://example.com/bg.jpg'\)}, inlined)
    end

    test "a section's own background image for Outlook, in its comments already, is left as it is" do
      mjml = "<mjml><mj-body><mj-section background-url=\"https://example.com/bg.jpg\"><mj-column><mj-text>In</mj-text></mj-column></mj-section></mj-body></mjml>"
      assert_equal MRML::Template.new(mjml).to_html, Mjml.compile(mjml).html
    end
  end
end
