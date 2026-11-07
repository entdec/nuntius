# frozen_string_literal: true

require "test_helper"

module Nuntius
  class OldLayoutTest < ActiveSupport::TestCase
    test "a template that still has an old layout renders inside it" do
      old_layout = OldLayout.create!(name: "Shop", data: %(<div class="shell">{{ content }}</div><footer>{{ template.layout.name }}</footer>))
      template = Template.new(transport: "mail", klass: "Custom", event: "welcome#x", html: "Hello {{ name }}", to: "test@example.com", old_layout: old_layout)

      message = template.new_message({}, {"name" => "Ann"})

      assert_includes message.html, %(<div class="shell"><p>Hello Ann</p>)
      assert_includes message.html, "<footer>Shop</footer>"
      assert template.translation_scope.start_with?("shop.")
    end

    test "an old layout in use can't be deleted" do
      old_layout = OldLayout.create!(name: "Shop", data: "{{ content }}")
      Template.create!(description: "Welcome", klass: "Custom", event: "welcome#x", transport: "mail", old_layout: old_layout)

      assert_not old_layout.destroy
    end
  end
end
