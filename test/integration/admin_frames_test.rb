# frozen_string_literal: true

require "test_helper"

# The admin pages in their frames (shared/_index, shared/_page), which a host app may draw its own way: an index
# page's title and actions over its table, a record's title, actions and Save over its tabs, without Satis
class AdminFramesTest < ActionDispatch::IntegrationTest
  test "the templates page has its title, New template and its table" do
    get "/nuntius/admin/templates"
    assert_response :success

    assert_select ".nuntius-index#nuntius_admin_templates" do
      assert_select ".nuntius-index__title", "Templates"
      assert_select ".nuntius-index__actions a.button[href='/nuntius/admin/templates/new']", /New template/
      assert_select ".mensa-table"
    end
    assert_select ".sts-card", count: 0
  end

  test "every index page is in its frame" do
    %w[campaigns layouts lists locales messages].each do |page|
      get "/nuntius/admin/#{page}"
      assert_response :success

      assert_select ".nuntius-index#nuntius_admin_#{page} .mensa-table"
      assert_select ".sts-card", count: 0
    end
  end

  test "a list's page is its form, with one Save, its actions, its subscribers and its settings beside them" do
    list = nuntius_lists(:valentines)

    get "/nuntius/admin/lists/#{list.id}/edit"
    assert_response :success

    assert_select "form[action='/nuntius/admin/lists/#{list.id}'] .nuntius-page#nuntius_admin_lists" do
      assert_select ".nuntius-page__actions button[type=submit]", count: 1
      assert_select ".nuntius-page__actions button[type=submit]", "Save"
      assert_select ".nuntius-page__actions a[href='/nuntius/admin/lists/#{list.id}/subscribers/new']"
      assert_select "[role=tab][aria-selected=true]", "Subscribers"
      assert_select "[role=tabpanel]:not([hidden]) .mensa-table"
      assert_select ".nuntius-page__aside input[name='list[name]'][value=?]", list.name
    end
    assert_select ".sts-card", count: 0
  end

  test "a list without subscribers is its settings" do
    list = Nuntius::List.create!(name: "Nieuw", slug: "nieuw")

    get "/nuntius/admin/lists/#{list.id}/edit"
    assert_response :success

    assert_select ".nuntius-page__aside", count: 0
    assert_select "[role=tabpanel] input[name='list[name]'][value=Nieuw]"
  end

  test "a locale's page is its form, without tabs" do
    get "/nuntius/admin/locales/#{nuntius_locales(:en).id}/edit"
    assert_response :success

    assert_select ".nuntius-page#nuntius_admin_locales" do
      assert_select "[role=tab]", count: 0
      assert_select ".nuntius-page__body input[name='locale[key]']"
    end
  end

  test "a message's page shows it, its details beside it, and resends it from its actions" do
    message = nuntius_messages(:one_recipient)

    get "/nuntius/admin/messages/#{message.id}"
    assert_response :success

    assert_select ".nuntius-page#nuntius_admin_messages" do
      assert_select "a[href='/nuntius/admin/messages/#{message.id}/resend'][data-turbo-method=post]"
      assert_select "[role=tabpanel] dl.nuntius-info dt", /To/
      assert_select "[role=tab]", text: "Details", count: 0
      assert_select ".nuntius-page__aside dl.nuntius-info dt", /State/
    end
  end

  test "a list's subscriber pages: a new one's form, and importing them" do
    list = nuntius_lists(:valentines)

    get "/nuntius/admin/lists/#{list.id}/subscribers/new"
    assert_response :success
    assert_select "form[action='/nuntius/admin/lists/#{list.id}/subscribers'] .nuntius-page" do
      assert_select "input[name='subscriber[email]']"
      assert_select "a[href='/nuntius/admin/lists/#{list.id}/edit']", "Back"
    end

    get "/nuntius/admin/lists/#{list.id}/subscribers/import"
    assert_response :success
    assert_select "form[action='/nuntius/admin/lists/#{list.id}/subscribers/import'][enctype='multipart/form-data']" do
      assert_select "input[type=file][name=file]"
      assert_select "button[type=submit]", "Import"
    end
  end

  test "an app with its own import has no Import of Nuntius'" do
    list = nuntius_lists(:valentines)

    Nuntius.config.stub(:subscribers_import, false) do
      get "/nuntius/admin/lists/#{list.id}/edit"
      assert_select ".nuntius-page__actions a[href='/nuntius/admin/lists/#{list.id}/subscribers/import']", count: 0
      assert_select ".nuntius-page__actions a[href='/nuntius/admin/lists/#{list.id}/subscribers/new']"

      get "/nuntius/admin/lists/#{list.id}/subscribers/import"
      assert_response :not_found
    end

    get "/nuntius/admin/lists/#{list.id}/edit"
    assert_select ".nuntius-page__actions a[href='/nuntius/admin/lists/#{list.id}/subscribers/import']"
  end
end
