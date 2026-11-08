# frozen_string_literal: true

require "test_helper"

# If [all] of the following conditions are met: [User › State] [is] [active]
class AdminConditionsFormTest < ActionDispatch::IntegrationTest
  def template_with(rules)
    Nuntius::Template.create!(description: "Welcome", klass: "User", event: "activate", transport: "sms", account: accounts(:one), conditions: {"match" => "any", "rules" => rules})
  end

  test "a template's conditions, with its variables by their names for people" do
    template = template_with([{"variable" => "user.state", "operator" => "is", "value" => "active"}, {"variable" => "user.active?", "operator" => "is", "value" => "false"}])

    get "/nuntius/admin/templates/#{template.id}/edit"

    assert_response :success
    assert_equal "any", css_select("select[name='template[conditions][match]'] option[selected]").first["value"]
    assert_equal "user.state", css_select("input[name='template[conditions][rules][0][variable]']").first["value"]
    assert_includes css_select(".entdec-variable-picker").first.text, "User › State"
    assert_equal "boolean", css_select(".entdec-conditions__rule[data-kind]")[1]["data-kind"]
    assert_equal "is", css_select("select[name='template[conditions][rules][0][operator]'] option[selected]").first["value"]
    assert_includes css_select(".entdec-variable-picker").first["data-entdec--variable-picker-url-value"], "/liquidum/variables"
    # and a row to add
    assert_select "template input[name='template[conditions][rules][NEW_RULE][variable]']"
  end

  test "a template's variables follow the class chosen in the form" do
    template = template_with([])

    get "/nuntius/admin/templates/#{template.id}/edit"

    switch = css_select("[data-controller~='nuntius--variables']").first
    assert_equal "template[klass]", switch["data-nuntius--variables-for-value"]
    urls = JSON.parse(switch["data-nuntius--variables-urls-value"])
    assert_includes urls.keys, "Account"
    assert_equal({"account" => "AccountDrop", "template" => "Nuntius::TemplateDrop"},
      Liquidum::Variables.from_token(Rack::Utils.parse_query(URI(urls["Account"]).query)["roots"]).roots.transform_values(&:name))
    # with the conditions and Liquid fields inside it
    assert_select "[data-controller~='nuntius--variables'] .entdec-conditions"
    assert_select "[data-controller~='nuntius--variables'] [data-controller='entdec--liquid-field'] input[name='template[to]']"
  end

  test "From, To and an SMS's text are Liquid fields, and the description has its Auto toggle" do
    template = template_with([])

    get "/nuntius/admin/templates/#{template.id}/edit"

    %w[from to].each do |field|
      assert_select "[data-controller='entdec--liquid-field'][data-entdec--liquid-field-url-value*='/liquidum/variables'] input[name='template[#{field}]']"
    end
    assert_select "template[data-toggle-value='sms'] [data-controller='entdec--liquid-field'] textarea[name='template[text]']"
    assert_select "template[data-toggle-value='teams'] [data-controller='entdec--liquid-field'] textarea[name='template[text]']"
    # and the code editors, Voice's TwiML with Liquid highlighted
    assert_select "template[data-toggle-value='voice'] [data-controller='entdec--liquid-field'] [data-controller='entdec--code-editor'][data-entdec--code-editor-lang-value='liquid'] input[type=hidden][name='template[text]']"
    assert_select "template[data-toggle-value='slack'] [data-controller='entdec--liquid-field'] [data-controller='entdec--code-editor']", count: 2
    assert_select "template[data-toggle-value='slack'] [data-entdec--code-editor-lang-value='yaml'] input[name='template[payload]']"
    assert_select "[data-controller='nuntius--description'] input[name='template[description]'][data-nuntius--description-target='field']"
    assert_select "input[type=checkbox][name='template[auto_description]'][data-nuntius--description-target='auto']"
    assert_select "[data-nuntius--description-target='sentence'] [data-description-skip]", minimum: 2
  end

  test "saving them, and leaving the rules without a variable out" do
    template = template_with([])

    patch "/nuntius/admin/templates/#{template.id}", params: {template: {conditions: {match: "all", rules: {
      "0" => {variable: "user.email", operator: "matches", value: "@example.com"},
      "1" => {variable: "", operator: "is", value: ""}
    }}}}

    assert_equal({"match" => "all", "rules" => [{"variable" => "user.email", "operator" => "matches", "value" => "@example.com", "value_to" => ""}]}, template.reload.conditions)

    patch "/nuntius/admin/templates/#{template.id}", params: {template: {conditions: {match: "all"}}}
    assert_equal [], template.reload.conditions["rules"]
  end

  test "a description made by hand stays when Auto is unchecked" do
    template = template_with([])
    assert template.auto_description
    get "/nuntius/admin/templates/new"
    assert_select "input[type=checkbox][name='template[auto_description]'][checked]"

    patch "/nuntius/admin/templates/#{template.id}", params: {template: {description: "Mine", auto_description: "0"}}

    assert_not template.reload.auto_description
    get "/nuntius/admin/templates/#{template.id}/edit"
    assert_select "input[type=checkbox][name='template[auto_description]']:not([checked])"
  end

  test "a campaign's conditions" do
    list = Nuntius::List.create!(name: "Members", slug: "members", account: accounts(:one))
    campaign = Nuntius::Campaign.create!(name: "News", transport: "sms", list: list, account: accounts(:one))

    patch "/nuntius/admin/campaigns/#{campaign.id}", params: {campaign: {conditions: {match: "any", rules: {"0" => {variable: "subscriber.first_name", operator: "isnt_empty"}}}}}
    assert_equal "subscriber.first_name", campaign.reload.conditions["rules"].first["variable"]

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert_includes css_select(".entdec-variable-picker").first.text, "Subscriber › First name"
  end
end
