# frozen_string_literal: true

require "test_helper"
require "liquid"

module Nuntius
  # The sample email's MJML (kept up to date by test/javascript/mjml_snapshot_test.mjs),
  # compiled as the editor does, then rendered with Liquid as a host app does
  # when it sends the email.
  class MjmlLiquidRenderTest < ActiveSupport::TestCase
    module MoneyFilter
      def money(value)
        Kernel.format("EUR %.2f", value)
      end
    end

    def render(assigns)
      template = Liquid::Template.parse(compiled_sample, error_mode: :strict)
      html = template.render!(assigns, filters: [MoneyFilter], strict_variables: true, strict_filters: true)
      [html, Nokogiri::HTML(html)]
    end

    def compiled_sample
      @compiled_sample ||= Mjml.compile(File.read(File.expand_path("../../javascript/snapshots/sample.mjml", __dir__))).html
    end

    def assigns(orders_count: 1)
      {
        "order" => {
          "number" => "1042",
          "url" => "https://shop.example/orders/1042",
          "lines" => [
            {"quantity" => 2, "name" => "Mug", "total" => 12.5},
            {"quantity" => 1, "name" => "Tea", "total" => 4}
          ]
        },
        "customer" => {"first_name" => "Ann", "orders_count" => orders_count},
        "unsubscribe_url" => "https://shop.example/unsubscribe"
      }
    end

    def text(document)
      document.text.gsub(/\s+/, " ")
    end

    test "the compiled HTML parses as strict Liquid and leaves no tags behind" do
      html, = render(assigns)
      assert_no_match(/\{\{|\{%/, html)
    end

    test "variables and filters in text, the title and the preview text" do
      _, document = render(assigns)
      assert_equal "Your order 1042", document.at("title").text
      assert_includes text(document), "Thanks for shopping with us, Ann."
      assert_includes text(document), "Thanks for your order, Ann!"
      assert_includes text(document), "We've received order 1042"
    end

    test "the loop repeats its block for every line" do
      _, document = render(assigns)
      assert_includes text(document), "2 × Mug — EUR 12.50"
      assert_includes text(document), "1 × Tea — EUR 4.00"
    end

    test "the loop renders nothing for an empty collection" do
      data = assigns
      data["order"]["lines"] = []
      _, document = render(data)
      assert_no_match(/ × /, text(document))
      assert_includes text(document), "View your order"
    end

    test "Liquid in links" do
      _, document = render(assigns)
      assert document.at_css('a[href="https://shop.example/orders/1042"]'), "button link"
      assert document.at_css('a[href="https://shop.example/unsubscribe"]'), "unsubscribe link"
    end

    test "the condition shows its section only when true" do
      _, first = render(assigns(orders_count: 1))
      _, later = render(assigns(orders_count: 3))
      assert_includes text(first), "This is your first order"
      assert_not_includes text(later), "This is your first order"
      assert_includes text(later), "ACME Store · Main Street 1"
    end

    test "the HTML stays a valid email layout after rendering" do
      _, document = render(assigns(orders_count: 3))
      # Removing the condition's section must not leave broken Outlook tables behind.
      assert_equal document.css("table").size, document.css("table").count { |table| table.at_css("tr") }
      assert document.at_css("body div[style*='background-color']"), "body wrapper"
    end
  end
end
