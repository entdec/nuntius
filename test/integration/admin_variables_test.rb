# frozen_string_literal: true

require "test_helper"

# The email editor's variable suggestions, from Liquidum's endpoint (mounted
# in the dummy app, as a host app does)
class AdminVariablesTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  setup do
    @layout = create_layout
    post "/nuntius/admin/templates", params: {template: {description: "Welcome", klass: "Account", event: "created", transport: "mail", to: "{{ account.email }}", layout_id: @layout.id}}
    @template = Nuntius::Template.find_by!(description: "Welcome")
  end

  def variables_url
    css_select("[data-controller='tess-edit']").first["data-tess-edit-variables-url-value"]
  end

  def variables(url, path = nil)
    get url, params: {path: path}.compact
    assert_response :success
    JSON.parse(response.body)["variables"].map { |variable| variable["name"] }
  end

  test "the template editor gets the template's variables" do
    get "/nuntius/admin/templates/#{@template.id}/edit"
    url = variables_url

    assert_match %r{\A/liquidum/variables\?roots=}, url
    assert_equal %w[account template], variables(url)
    assert_includes variables(url, "account"), "name"
    assert_includes variables(url, "template"), "layout"
  end

  test "the layout editor gets the variables of the templates and campaigns it's part of" do
    get "/nuntius/admin/layouts/#{@layout.id}/edit"

    assert_equal %w[template campaign], variables(variables_url)
  end

  test "the endpoint refuses roots that are not signed" do
    get "/liquidum/variables", params: {roots: {template: {drop: "Nuntius::TemplateDrop"}}.to_json}

    assert_response :bad_request
  end
end
