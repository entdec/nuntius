# frozen_string_literal: true

require "test_helper"

# A record that doesn't save shows its form again, with what was filled in, and the notification says why
class AdminFormErrorsTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  setup do
    @layout = create_layout
    @list = Nuntius::List.create!(name: "Newsletter", slug: "newsletter")
  end

  # The error notifications sent while yielding, through a stand-in for Signum (which Nuntius doesn't depend on)
  # and a current user, which the dummy app doesn't have
  def notifications
    texts = []
    Object.const_set(:Signum, Module.new { define_singleton_method(:error) { |_user, text:, **| texts << text } })
    Nuntius::ApplicationAdminController.define_method(:current_user) { nil }
    yield
    texts
  ensure
    Nuntius::ApplicationAdminController.remove_method(:current_user)
    Object.send(:remove_const, :Signum)
  end

  test "a new campaign that doesn't save shows its form with what was filled in" do
    texts = notifications do
      post "/nuntius/admin/campaigns", params: {campaign: {name: "", subject: "Spring", transport: "mail", layout_id: @layout.id, list_id: @list.id}}
    end

    assert_response :unprocessable_entity
    assert_not Nuntius::Campaign.exists?(subject: "Spring")
    assert_select "select[name='campaign[list_id]'] option[selected][value='#{@list.id}']"
    assert_select "[data-controller='tess-edit']"
    assert_match(/Name/, texts.sole)
  end

  test "a new template that doesn't save shows its form with what was filled in" do
    texts = notifications do
      post "/nuntius/admin/templates", params: {template: {description: "", klass: "Custom", event: "order#placed", transport: "mail", to: "{{ order.email }}", layout_id: @layout.id}}
    end

    assert_response :unprocessable_entity
    assert_select "input[name='template[event]'][value='order#placed']"
    assert_match(/Description/, texts.sole)
  end

  test "a new layout that doesn't save shows its form with what was filled in" do
    texts = notifications do
      post "/nuntius/admin/layouts", params: {layout: {name: "Imported", design_json: layout_json.to_json, design_mjml: "<mjml><mj-body></mj-body></mjml>"}}
    end

    assert_response :unprocessable_entity
    assert_not Nuntius::Layout.exists?(name: "Imported")
    assert_select "input[name='layout[name]'][value='Imported']"
    assert_select "[role='alert']", /Content block/
    assert_match(/Content block/, texts.sole)
  end
end
