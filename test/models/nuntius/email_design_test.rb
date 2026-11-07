# frozen_string_literal: true

require "test_helper"

module Nuntius
  class EmailDesignTest < ActiveSupport::TestCase
    include EmailDesignHelper

    test "takes the content out of the MJML" do
      assert_includes EmailDesign.content_of(layout_mjml(example: "Mine")), "<mj-text>Mine</mj-text>"
    end

    test "needs exactly one Content block" do
      assert_raises(EmailDesign::Error) { EmailDesign.content_of("<mjml><mj-body></mj-body></mjml>") }
      assert_raises(EmailDesign::Error) { EmailDesign.content_of(content_mjml("a") + content_mjml("b")) }
    end

    test "puts content, subject and preview text into the layout" do
      mjml = EmailDesign.merge(layout_mjml, "<mj-section><mj-column><mj-text>Mine</mj-text></mj-column></mj-section>", subject: "Order {{ order.number }} & more", preview_text: "Hi <there>")

      assert_includes mjml, "<mj-text>Mine</mj-text>"
      assert_not_includes mjml, "Example content"
      assert_includes mjml, "<mj-text>ACME</mj-text>"
      assert_includes mjml, "<mj-title>Order {{ order.number }} &amp; more</mj-title>"
      assert_includes mjml, "<mj-preview>Hi &lt;there&gt;</mj-preview>"
      assert_not_includes mjml, "Layout title"
      assert TessEdit.compile(mjml).html
    end

    test "escaping leaves Liquid alone" do
      assert_equal %(a &lt; b {{ "x" | append: '<' }} {% if a > b %}), EmailDesign.escape_text(%(a < b {{ "x" | append: '<' }} {% if a > b %}))
    end

    test "puts blocks into the layout's document and takes them out again" do
      document = EmailDesign.document_with(layout_json, [text_node("bmine", "Mine")], subject: "Hi", preview_text: "There")

      assert_equal ["bmine"], EmailDesign.content_nodes(document).map { |node| node["id"] }
      assert_equal "Hi", document.dig("data", "subject")
      assert_equal "There", document.dig("data", "preheader")
      assert_equal ["bexample"], EmailDesign.content_nodes(layout_json).map { |node| node["id"] }, "the layout's document is left as it was"
    end
  end
end
