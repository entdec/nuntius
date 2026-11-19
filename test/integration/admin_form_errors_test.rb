# frozen_string_literal: true

require "test_helper"

# A record that doesn't save shows its form again, with what was filled in, and the page says why
class AdminFormErrorsTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  setup do
    @layout = create_layout
    @list = Nuntius::List.create!(name: "Newsletter", slug: "newsletter")
  end

  test "a new campaign that doesn't save shows its form with what was filled in" do
    post "/nuntius/admin/campaigns", params: {campaign: {name: "", subject: "Spring", transport: "mail", layout_id: @layout.id, list_id: @list.id}}

    assert_response :unprocessable_entity
    assert_not Nuntius::Campaign.exists?(subject: "Spring")
    assert_select "select[name='campaign[list_id]'] option[selected][value='#{@list.id}']"
    assert_select "[data-controller='tess-edit']"
    assert_select ".nuntius-page__errors[role=alert]", /Name/
  end

  test "a new template that doesn't save shows its form with what was filled in" do
    post "/nuntius/admin/templates", params: {template: {description: "", klass: "Custom", event: "order#placed", transport: "mail", to: "{{ order.email }}", layout_id: @layout.id}}

    assert_response :unprocessable_entity
    assert_select "input[name='template[event]'][value='order#placed']"
    assert_select ".nuntius-page__errors[role=alert]", /Description/
  end

  test "a new layout that doesn't save shows its form with what was filled in" do
    post "/nuntius/admin/layouts", params: {layout: {name: "Imported", design_json: layout_json.to_json, design_mjml: "<mjml><mj-body></mj-body></mjml>"}}

    assert_response :unprocessable_entity
    assert_not Nuntius::Layout.exists?(name: "Imported")
    assert_select "input[name='layout[name]'][value='Imported']"
    assert_select ".nuntius-page__errors[role=alert]", /Content block/
  end

  test "a record that saves says nothing about it" do
    list = nuntius_lists(:valentines)

    patch "/nuntius/admin/lists/#{list.id}", params: {list: {name: "Valentine's"}}
    follow_redirect!

    assert_select ".nuntius-page__errors", count: 0
    assert_nil flash[:notice]
  end
end
