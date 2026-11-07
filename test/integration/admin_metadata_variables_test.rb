# frozen_string_literal: true

require "test_helper"

# Designs in the email editor are warned about metadata variables they still use
class AdminMetadataVariablesTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  test "a template's design that reads metadata is warned about, with the value its metadata has" do
    layout = create_layout(header: "<img src=\"{{ template.metadata.logo_url }}\">")
    post "/nuntius/admin/templates", params: {template: {description: "Order", klass: "Custom", event: "order#placed", transport: "mail", to: "x@example.com", layout_id: layout.id}}
    template = Nuntius::Template.find_by!(description: "Order")
    template.update_columns(metadata: {"logo_url" => "{{ user.account.logo_path }}"})

    get "/nuntius/admin/templates/#{template.id}/edit"

    assert_select "[role='status']", /template\.metadata\.logo_url/
    assert_select "[role='status'] code", "{{ user.account.logo_path }}"
  end

  test "a layout that reads metadata is warned about" do
    layout = create_layout(header: "{{ layout.metadata['color'] }}")

    get "/nuntius/admin/layouts/#{layout.id}/edit"

    assert_select "[role='status']", /layout\.metadata\.color/
  end

  test "a design without metadata variables gets no warning" do
    get "/nuntius/admin/layouts/#{create_layout.id}/edit"

    assert_select "[role='status']", count: 0
  end

  test "a template with an old layout that reads metadata is warned about before converting" do
    create_layout
    old_layout = Nuntius::OldLayout.create!(name: "Old", data: "<img src=\"{{ template.metadata.logo_url }}\">{{ content }}")
    template = Nuntius::Template.create!(description: "Old", klass: "Account", event: "created", transport: "mail", to: "x@example.com", html: "Hi", old_layout: old_layout, metadata: {"logo_url" => "logo.png"})

    get "/nuntius/admin/templates/#{template.id}/edit"

    assert_select "[role='status']", /template\.metadata\.logo_url/
    assert_select "[role='status'] code", "logo.png"
  end
end
