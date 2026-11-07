# frozen_string_literal: true

require "test_helper"

# The admin shows and changes the current account's records only (the dummy
# app's admin is account one's)
class AdminAccountsTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  setup do
    @other = Account.create!(name: "other")
    @layout = create_layout
    @other_layout = Nuntius::Layout.create!(name: "Other layout", json: layout_json, mjml: layout_mjml, account: @other)
    @template = Nuntius::Template.create!(description: "Own template", klass: "Account", event: "created", transport: "sms", text: "Hi")
    @other_template = Nuntius::Template.create!(description: "Other template", klass: "Account", event: "created", transport: "mail", account: @other, global: true)
  end

  teardown do
    Nuntius.config.can_create_global = -> { false }
  end

  test "lists the account's own records, not another account's, also not its global templates" do
    get_table "templates"

    assert_includes response.body, "Own template"
    assert_not_includes response.body, "Other template"

    get_table "layouts"

    assert_includes response.body, "ACME"
    assert_not_includes response.body, "Other layout"
  end

  test "another account's records can't be opened, changed or deleted" do
    get "/nuntius/admin/templates/#{@other_template.id}/edit"
    assert_response :not_found
    patch "/nuntius/admin/layouts/#{@other_layout.id}", params: {layout: {name: "Mine"}}
    assert_response :not_found
    delete "/nuntius/admin/templates/#{@other_template.id}"
    assert_response :not_found
    get "/nuntius/admin/layouts/#{@other_layout.id}/media"
    assert_response :not_found

    assert_equal "Other layout", @other_layout.reload.name
    assert Nuntius::Template.exists?(@other_template.id)
  end

  test "a new record belongs to the current account" do
    post "/nuntius/admin/lists", params: {list: {name: "News", slug: "news"}}

    assert_equal accounts(:one), Nuntius::List.find_by!(slug: "news").account
  end

  test "the layout picker offers the account's own layouts, and another account's can't be chosen" do
    get "/nuntius/admin/templates/new"

    assert_select "select[name='template[layout_id]'] option[value='#{@layout.id}']"
    assert_select "select[name='template[layout_id]'] option[value='#{@other_layout.id}']", count: 0

    post "/nuntius/admin/templates", params: {template: {description: "Order", klass: "Custom", event: "order#placed", transport: "mail", to: "x@example.com", layout_id: @other_layout.id}}

    assert_not Nuntius::Template.exists?(description: "Order")
  end

  test "a campaign can't use another account's list" do
    other_list = Nuntius::List.create!(name: "Other list", slug: "other-list", account: @other)
    campaign = Nuntius::Campaign.new(name: "News", transport: "sms", list: other_list)

    assert_not campaign.valid?
    assert campaign.errors.added?(:list, :other_account)
  end

  test "a global switch is there only when the account may make templates global" do
    get "/nuntius/admin/templates/new"
    assert_select "input[name='template[global]']", count: 0

    patch "/nuntius/admin/templates/#{@template.id}", params: {template: {global: "1"}}
    assert_not @template.reload.global

    Nuntius.config.can_create_global = -> { true }

    get "/nuntius/admin/templates/new"
    assert_select "input[name='template[global]']"

    patch "/nuntius/admin/templates/#{@template.id}", params: {template: {global: "1"}}
    assert @template.reload.global
  end

  test "metadata can only be edited for a template with an old layout" do
    get "/nuntius/admin/templates/#{@template.id}/edit"
    assert_select "[name='template[metadata_yaml]']", count: 0

    patch "/nuntius/admin/templates/#{@template.id}", params: {template: {metadata_yaml: "logo_url: logo.png"}}
    assert_equal({}, @template.reload.metadata)

    @template.update!(old_layout: nuntius_old_layouts(:one))
    get "/nuntius/admin/templates/#{@template.id}/edit"
    assert_select "[name='template[metadata_yaml]']"

    get "/nuntius/admin/layouts/#{@layout.id}/edit"
    assert_select "[name='layout[metadata_yaml]']", count: 0
  end

  test "a message from another account's global template shows the template without a link to it" do
    Nuntius::Message.create!(transport: "mail", to: "user@example.com", template: @other_template)

    get_table "messages"

    assert_includes response.body, "Other template"
    assert_select "a[href='/nuntius/admin/templates/#{@other_template.id}/edit']", count: 0
  end

  test "a cancelled campaign is shown like a sent one, without a form or a publish action" do
    campaign = nuntius_campaigns(:valentines_day)
    campaign.update_columns(transport: "mail")
    campaign.cancel!

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert_response :success
    assert_select "form[action='/nuntius/admin/campaigns/#{campaign.id}']", count: 0
    assert_includes response.body, "Valentines day 2020"

    get_table "campaigns"
    assert_includes response.body, "cancelled"
    assert_not_includes response.body, "/nuntius/admin/campaigns/#{campaign.id}/publish"
  end

  test "a draft or sending campaign can be cancelled from the admin, another account's not" do
    campaign = nuntius_campaigns(:valentines_day)
    campaign.update_column(:state, "sending")

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert_select "form[action='/nuntius/admin/campaigns/#{campaign.id}/cancel'][data-turbo-confirm^='Are you sure you want to cancel']"
    get_table "campaigns"
    assert_includes response.body, "/nuntius/admin/campaigns/#{campaign.id}/cancel"
    assert_includes response.body, "Are you sure you want to cancel this campaign?"

    post "/nuntius/admin/campaigns/#{campaign.id}/cancel"
    assert_redirected_to "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert campaign.reload.cancelled?

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert_select "form[action='/nuntius/admin/campaigns/#{campaign.id}/cancel']", count: 0

    other = Nuntius::Campaign.create!(name: "Other", transport: "sms", list: Nuntius::List.create!(name: "Other list", slug: "other-list", account: @other), account: @other)
    post "/nuntius/admin/campaigns/#{other.id}/cancel"
    assert_response :not_found
    assert other.reload.draft?
  end

  private

  # The rows of an admin table, which its page loads separately
  def get_table(name)
    get "/mensa/tables/nuntius%2F#{name}", params: {turbo_frame_id: "table"}
    assert_response :success
  end
end
