# frozen_string_literal: true

require "test_helper"

module Nuntius
  class TemplatePreviewTest < ActiveSupport::TestCase
    def preview(text, klass: "User")
      TemplatePreview.new(Template.new(transport: "sms", klass: klass, text: text)).to_h[:text]
    end

    test "variables show as samples, also below unknown ones, in loops and in conditions" do
      assert_equal "‹user.nothing.deeper›", preview("{{ user.nothing.deeper }}")
      assert_equal "‹user.addresses.street›", preview("{% for address in user.addresses %}{{ address.street }}{% endfor %}")
      assert_equal "yes", preview("{% if user.active %}yes{% endif %}")
      assert_equal "1", preview("{{ user.addresses.size }}")
    end

    test "a variable Liquidum knows shows as its label" do
      assert_match(/\A‹User › .+›\z/, preview("{{ user.name }}"))
    end

    test "a variable that isn't the class's shows as a sample too" do
      assert_equal "Hi ‹order.number›", preview("Hi {{ order.number }}")
      assert_equal "Hi ‹user.name›", preview("Hi {{ user.name }}", klass: nil)
    end
  end
end
