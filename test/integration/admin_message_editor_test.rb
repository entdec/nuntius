# frozen_string_literal: true

require "test_helper"

# The editors of SMS, Push, Teams, Slack and Voice templates
# (app/javascript/nuntius/kits/messages.js)
class AdminMessageEditorTest < ActionDispatch::IntegrationTest
  def template(**attributes)
    Nuntius::Template.create!({description: "Welcome", klass: "User", event: "activate", transport: "sms", text: "Hi {{ user.name }}", to: "{{ user.phone_number }}", account: accounts(:one)}.merge(attributes))
  end

  def editor
    css_select("[data-controller='tess-edit']").first
  end

  def document
    JSON.parse(css_select("input[name='template[design_json]']").first["value"])
  end

  test "a template of each transport opens the editor of its messages, with its settings in its root" do
    {"sms" => %w[from to text], "push" => %w[from to text payload], "teams" => %w[from to text payload], "slack" => %w[from to text payload], "voice" => %w[from to text]}.each do |transport, keys|
      record = template(transport: transport, payload: ("blocks: []" if keys.include?("payload")))

      get "/nuntius/admin/templates/#{record.id}/edit"

      assert_response :success
      assert_equal transport, editor["data-tess-edit-kit-value"]
      assert_equal({"template" => true, "previewUrl" => "/nuntius/admin/templates/preview"}, JSON.parse(editor["data-tess-edit-options-value"]))
      assert_equal transport, document["type"]
      assert_equal keys.sort, document["data"].keys.sort
      assert_select "[data-controller='tess-edit'] [data-tess-edit-slot='trigger'] select[name='template[klass]']"
      assert_select "[data-tess-edit-slot='layout']", count: 0
      assert_select "[name='template[text]'], [name='template[payload]']", count: 0
    end
  end

  test "saving takes its settings from the editor" do
    record = template(transport: "slack")
    design = {"id" => "broot", "type" => "slack", "data" => {"text" => "Shipped {{ order.number }}", "payload" => "blocks: []", "to" => "#orders"}, "children" => []}

    patch "/nuntius/admin/templates/#{record.id}", params: {template: {description: "Shipped", design_json: design.to_json}}

    record.reload
    assert_equal "Shipped {{ order.number }}", record.text
    assert_equal "blocks: []", record.payload
    assert_equal "#orders", record.to
  end

  test "a new one is made in the editor, and its errors show above it" do
    design = {"id" => "broot", "type" => "sms", "data" => {"text" => "{% if user %}Hi"}, "children" => []}

    post "/nuntius/admin/templates", params: {template: {description: "Hi", klass: "User", event: "activate", transport: "sms", design_json: design.to_json}}

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Text is not valid liquid/
    assert_equal "{% if user %}Hi", document["data"]["text"]
  end

  test "the preview renders the message with sample values" do
    post "/nuntius/admin/templates/preview", params: {template: {transport: "slack", klass: "User", text: "Hi {{ user.name }} {{ user.nothing }}", payload: "title: \"{{ user.name }}\"\nn: 1"}}

    assert_response :success
    preview = response.parsed_body
    assert_equal "Hi ‹User › Name› ‹user.nothing›", preview["text"]
    assert_equal 1, preview["payload"]["n"]
    assert_match(/\A‹.+›\z/, preview["payload"]["title"])
    assert_equal [], preview["errors"]
  end

  test "the preview says when its payload isn't YAML" do
    post "/nuntius/admin/templates/preview", params: {template: {transport: "push", klass: "User", text: "Hi", payload: "a: [1"}}

    assert_match(/isn't valid YAML/, response.parsed_body["errors"].first)
    assert_nil response.parsed_body["payload"]
  end

  test "an SMS campaign opens the editor of its messages, and saves its text from it" do
    campaign = Nuntius::Campaign.create!(name: "News", transport: "sms", list: nuntius_lists(:valentines), text: "Hi")

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"

    assert_equal "sms", editor["data-tess-edit-kit-value"]
    assert_equal({"campaign" => true, "previewUrl" => "/nuntius/admin/templates/preview"}, JSON.parse(editor["data-tess-edit-options-value"]))
    document = JSON.parse(css_select("input[name='campaign[design_json]']").first["value"])
    assert_equal({"from" => nil, "text" => "Hi"}, document["data"])
    assert_select "[data-controller='tess-edit'] [data-tess-edit-slot='audience'] select[name='campaign[list_id]']"

    document["data"]["text"] = "Hi {{ subscriber.first_name }}"
    patch "/nuntius/admin/campaigns/#{campaign.id}", params: {campaign: {design_json: document.to_json}}

    assert_equal "Hi {{ subscriber.first_name }}", campaign.reload.text
  end
end
