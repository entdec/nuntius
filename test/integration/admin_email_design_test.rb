# frozen_string_literal: true

require "test_helper"

class AdminEmailDesignTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  setup do
    @layout = create_layout
  end

  def template_attributes(**attributes)
    {description: "Order", klass: "Custom", event: "order#placed", transport: "mail", to: "{{ order.email }}", layout_id: @layout.id}.merge(attributes)
  end

  def editor_value(name)
    css_select("[data-controller='tess-edit']").first["data-tess-edit-#{name}-value"]
  end

  test "the layout editor opens a new layout with a starting design" do
    get "/nuntius/admin/layouts/new"

    assert_response :success
    assert_equal "/nuntius/tess_edit/compile", editor_value("compile-url")
    assert_select "input[name='layout[design_json]']"
    assert_select "input[name='layout[design_mjml]']"
  end

  test "a new layout can start from one of the starting layouts" do
    get "/nuntius/admin/layouts/new", params: {start: "newsletter"}

    assert_response :success
    assert_select "a[href='/nuntius/admin/layouts/new?start=transactional']"
    document = JSON.parse(css_select("input[name='layout[design_json]']").first["value"])
    assert_equal Nuntius::Layout.starting_document("newsletter"), document
    assert_select "textarea[name='layout[description]']", text: /columns for articles/
  end

  test "a layout's description is saved, and its preview has its images and no Liquid" do
    post "/nuntius/admin/layouts", params: {layout: {name: "Newsletter", description: "For news", design_json: layout_json.to_json, design_mjml: layout_mjml(header: "NEWS {{ template.description }}")}}

    layout = Nuntius::Layout.find_by!(name: "Newsletter")
    assert_equal "For news", layout.description
    assert_includes layout.preview_html, "NEWS"
    assert_not_includes layout.preview_html, "{{"
  end

  test "saving a layout takes the design from the editor" do
    post "/nuntius/admin/layouts", params: {layout: {name: "Newsletter", design_json: layout_json.to_json, design_mjml: layout_mjml(header: "NEWS")}}

    layout = Nuntius::Layout.find_by!(name: "Newsletter")
    assert_includes layout.html, "NEWS"
  end

  test "a layout submitted with CRLF line endings, as browsers do, saves" do
    patch "/nuntius/admin/layouts/#{@layout.id}", params: {layout: {name: "ACME", design_json: layout_json.to_json, design_mjml: layout_mjml(header: "CRLF").gsub("\n", "\r\n")}}

    assert_includes @layout.reload.html, "CRLF"
    assert_not_includes @layout.mjml, "\r"
  end

  test "a layout that does not compile shows why" do
    patch "/nuntius/admin/layouts/#{@layout.id}", params: {layout: {name: "ACME", design_json: layout_json.to_json, design_mjml: "<mjml><mj-body></mj-body></mjml>"}}

    assert_select "[role='alert']", /Content block/
  end

  test "a new mail template needs a layout" do
    post "/nuntius/admin/templates", params: {template: template_attributes(layout_id: "")}

    assert_not Nuntius::Template.exists?(description: "Order")
  end

  test "a new mail template starts with the layout's example content" do
    post "/nuntius/admin/templates", params: {template: template_attributes}

    template = Nuntius::Template.find_by!(description: "Order")
    assert_includes template.html, "Example content"
    assert_includes template.html, "ACME"
  end

  test "the template editor shows the layout, locked except its own content" do
    post "/nuntius/admin/templates", params: {template: template_attributes}
    template = Nuntius::Template.find_by!(description: "Order")

    get "/nuntius/admin/templates/#{template.id}/edit"

    assert_response :success
    assert_equal Nuntius::Concerns::EmailDesigned::EDITOR_LOCK.as_json, JSON.parse(editor_value("lock"))
    document = JSON.parse(css_select("input[name='template[design_json]']").first["value"])
    assert_equal ["bheader", "bcontent"], document["children"].map { |node| node["id"] }
    assert_not_includes response.body, "template[html]"
  end

  test "saving a template takes its own content from the editor" do
    post "/nuntius/admin/templates", params: {template: template_attributes}
    template = Nuntius::Template.find_by!(description: "Order")
    design = submitted_design(@layout, text: "Your order is on its way", header: "CHANGED IN THE BROWSER")

    patch "/nuntius/admin/templates/#{template.id}", params: {template: {description: "Order", design_json: design[:document], design_mjml: design[:mjml]}}

    template.reload
    assert_equal "Order {{ order.number }}", template.subject
    assert_includes template.html, "Your order is on its way"
    assert_not_includes template.html, "CHANGED IN THE BROWSER"
  end

  test "choosing another layout moves the template's content into it" do
    post "/nuntius/admin/templates", params: {template: template_attributes}
    template = Nuntius::Template.find_by!(description: "Order")
    other = Nuntius::Layout.create!(name: "Other", json: layout_json, mjml: layout_mjml(header: "OTHER"))

    patch "/nuntius/admin/templates/#{template.id}", params: {template: {layout_id: other.id}}

    assert_includes template.reload.html, "OTHER"
    assert_includes template.html, "Example content"
  end

  test "a template with an old layout keeps its old fields" do
    template = Nuntius::Template.create!(template_attributes(layout_id: nil, old_layout: nuntius_old_layouts(:one), subject: "Hi", html: "# Hello"))

    get "/nuntius/admin/templates/#{template.id}/edit"

    assert_response :success
    assert_select "[data-controller='tess-edit']", count: 0
    assert_includes response.body, "template[html]"
  end

  test "the campaign editor shows the layout, locked except its own content" do
    list = nuntius_lists(:valentines)
    list.update_column(:slug, "valentines")
    post "/nuntius/admin/campaigns", params: {campaign: {name: "Spring", transport: "mail", layout_id: @layout.id, list_id: list.id}}
    campaign = Nuntius::Campaign.find_by!(name: "Spring")

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"

    assert_response :success
    assert_includes campaign.html, "Example content"
    assert_equal Nuntius::Concerns::EmailDesigned::EDITOR_LOCK.as_json, JSON.parse(editor_value("lock"))
  end

  test "converting a template with an old layout from its page" do
    template = Nuntius::Template.create!(template_attributes(layout_id: nil, old_layout: nuntius_old_layouts(:one), subject: "Hi", html: "<p>Hello</p>"))

    get "/nuntius/admin/templates/#{template.id}/edit"
    assert_select "button[formaction='/nuntius/admin/templates/#{template.id}/convert']"

    patch "/nuntius/admin/templates/#{template.id}/convert", params: {template: {layout_id: @layout.id}}

    assert_redirected_to "/nuntius/admin/templates/#{template.id}/edit"
    assert template.reload.email_design?
    assert_includes template.html, "Hello"
  end

  test "converting without a layout shows why" do
    template = Nuntius::Template.create!(template_attributes(layout_id: nil, old_layout: nuntius_old_layouts(:one), subject: "Hi", html: "<p>Hello</p>"))

    patch "/nuntius/admin/templates/#{template.id}/convert", params: {template: {layout_id: ""}}

    assert_response :unprocessable_entity
    assert_includes response.body, "Choose a layout"
    assert_not template.reload.email_design?
  end
end
