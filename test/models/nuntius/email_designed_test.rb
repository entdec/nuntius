# frozen_string_literal: true

require "test_helper"

module Nuntius
  class EmailDesignedTest < ActiveSupport::TestCase
    include EmailDesignHelper

    def template_in(layout, text: "Your order {{ order.number }}")
      template = Template.new(description: "Order", klass: "Custom", event: "order#placed", transport: "mail", to: "test@example.com", layout: layout)
      template.assign_design(**submitted_design(layout, text: text))
      template.save!
      template
    end

    test "a template takes its own content, subject and preview text from the editor, and the rest from the layout" do
      layout = create_layout
      template = Template.new(description: "Order", klass: "Custom", event: "order#placed", transport: "mail", layout: layout)
      template.assign_design(**submitted_design(layout, text: "Mine", header: "CHANGED IN THE BROWSER"))

      assert template.save
      assert_equal ["bmine"], template.json.map { |node| node["id"] }
      assert_equal "Order {{ order.number }}", template.subject
      assert_equal "Thanks", template.preview_text
      assert_includes template.html, "Mine"
      assert_includes template.html, "ACME"
      assert_not_includes template.html, "CHANGED IN THE BROWSER"
      assert_includes template.html, "<title>Order {{ order.number }}</title>"
    end

    test "the editor opens the layout with the template's own content in it" do
      layout = create_layout
      document = template_in(layout).editor_document

      assert_equal ["bheader", "bcontent"], document["children"].map { |node| node["id"] }
      assert_equal ["bmine"], EmailDesign.content_nodes(document).map { |node| node["id"] }
      assert_equal "Order {{ order.number }}", document.dig("data", "subject")
    end

    test "sending renders the Liquid in the whole email, without Markdown" do
      template = template_in(create_layout)

      message = template.new_messages({}, {"order" => {"number" => "1042"}}).first

      assert_includes message.html, "Your order 1042"
      assert_includes message.html, "<title>Order 1042</title>"
      assert_includes message.html, "ACME Store · Main Street 1"
      assert_equal "Order 1042", message.subject
    end

    test "templates and draft campaigns follow their layout, sent campaigns don't" do
      layout = create_layout
      template = template_in(layout)
      draft = Campaign.new(name: "News", list: nuntius_lists(:valentines), layout: layout, state: "draft")
      draft.assign_design(**submitted_design(layout, text: "Draft news"))
      draft.save!
      sent = Campaign.new(name: "Old news", list: nuntius_lists(:valentines), layout: layout, state: "sent")
      sent.assign_design(**submitted_design(layout, text: "Sent news"))
      sent.save!

      assert layout.update(mjml: layout_mjml(header: "NEW HEADER"))

      assert_includes template.reload.html, "NEW HEADER"
      assert_includes template.html, "Your order {{ order.number }}"
      assert_includes draft.reload.html, "NEW HEADER"
      assert_includes draft.html, "Draft news"
      assert_not_includes sent.reload.html, "NEW HEADER"
    end

    test "a layout change a template can't follow isn't saved" do
      layout = create_layout
      template = template_in(layout)
      # Without <mj-head> there is nowhere to put the template's subject
      headless = layout_mjml(header: "NEW HEADER").sub(%r{<mj-head>.*?</mj-head>}m, "")

      assert_not layout.update(mjml: headless)
      assert_includes layout.errors.full_messages.to_sentence, "could not follow the layout"
      assert_not_includes layout.reload.mjml, "NEW HEADER"
      assert_not_includes template.reload.html, "NEW HEADER"
    end

    test "a layout needs exactly one Content block" do
      layout = Layout.new(name: "No content", json: {}, mjml: "<mjml><mj-body><mj-section><mj-column><mj-text>Hi</mj-text></mj-column></mj-section></mj-body></mjml>")

      assert_not layout.valid?
      assert_includes layout.errors.full_messages.to_sentence, "exactly one Content block"
    end

    test "a design without a layout is an error, not an exception" do
      template = Template.new(description: "Order", klass: "Custom", event: "order#placed", transport: "mail")
      template.assign_design(document: layout_json.to_json, mjml: layout_mjml)

      assert_not template.valid?
      assert_includes template.errors.full_messages.to_sentence, "Choose a layout"
    end
  end
end
