# frozen_string_literal: true

require "test_helper"

# The template form reads as a sentence: send via [mail] when on [a user] [activated]
class AdminTemplateFormTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  test "a new template starts with what it sends, the common ones first, then opens its editor" do
    get "/nuntius/admin/templates/new"

    assert_response :success
    links = css_select("a[href^='/nuntius/admin/templates/new?transport=']").map { |link| link["href"] }
    assert_equal %w[mail sms push voice].map { |transport| "/nuntius/admin/templates/new?transport=#{transport}" }, links
    assert_select "input[name='template[transport]']", count: 0

    get "/nuntius/admin/templates/new", params: {transport: "sms"}

    assert_select "input[type=hidden][name='template[transport]'][value='sms']"
    assert_select ".nuntius-sentence span", text: "SMS"
    assert_select "[data-controller='tess-edit'][data-tess-edit-kit-value='sms']"
    assert_select "select[name='template[layout_id]']", count: 0
    assert_select "a.button[href='/nuntius/admin/templates/new']", text: "Back"
  end

  test "a new email starts from a layout, with its preview, name and description" do
    layout = nuntius_layouts(:one)
    layout.update!(description: "For receipts", json: layout_json, mjml: layout_mjml)
    other = Nuntius::Layout.create!(name: "Newsletter", json: layout_json, mjml: layout_mjml(header: "NEWS"), account: accounts(:one))

    get "/nuntius/admin/templates/new", params: {transport: "mail"}

    assert_select "a[href='/nuntius/admin/templates/new']", text: /Back/
    assert_select "a[href^='/nuntius/admin/templates/new?transport=sms']", count: 0
    assert_equal [other.id, layout.id].sort, css_select("a[href*='layout_id=']").map { |link| link["href"][/layout_id=([\w-]+)/, 1] }.sort
    assert_select "iframe[srcdoc][sandbox]", count: 2
    assert_select "span", text: "For receipts"

    get "/nuntius/admin/templates/new", params: {transport: "mail", layout_id: other.id}

    assert_select "input[type=hidden][name='template[transport]'][value='mail']"
    assert_select "select[name='template[layout_id]'] option[selected][value='#{other.id}']"
    assert_select "[data-controller~='tess-edit']"
    assert_select "a.button[href='/nuntius/admin/templates/new?transport=mail']", text: "Back"
    assert_not Nuntius::Template.exists?(layout_id: other.id)
  end

  test "an email with only one layout to start from starts from it" do
    nuntius_layouts(:one).update!(json: layout_json, mjml: layout_mjml)

    get "/nuntius/admin/templates/new", params: {transport: "mail"}

    assert_select "select[name='template[layout_id]'] option[selected][value='#{nuntius_layouts(:one).id}']"
  end

  test "without layouts an email can't start, and says to create one" do
    Nuntius::Template.update_all(layout_id: nil)
    Nuntius::Campaign.update_all(layout_id: nil)
    Nuntius::Layout.delete_all

    get "/nuntius/admin/templates/new", params: {transport: "mail"}

    assert_select "a[href='/nuntius/admin/layouts/new']", text: /Create a layout first/
    assert_select "a[href*='layout_id=']", count: 0
  end

  test "what a template sends stays as it was made" do
    template = Nuntius::Template.create!(description: "Welcome", klass: "User", event: "activate", transport: "sms", account: accounts(:one))

    patch "/nuntius/admin/templates/#{template.id}", params: {template: {transport: "push", text: "Hi"}}

    assert_equal "sms", template.reload.transport
    assert_equal "Hi", template.text
  end

  test "the enabled templates, of all transports or one, as the table's views" do
    views = Nuntius::TemplatesTable.new.all_views

    assert_equal ["All", "Email", "SMS", "Push notification", "Voice"], views.map(&:name)
    views.each { |view| assert_equal true, view.config.dig(:filters, :enabled, :value) }
    assert_equal "sms", views.find { |view| view.name == "SMS" }.config.dig(:filters, :transport, :value)
  end

  test "the classes and events by their names for people" do
    I18n.backend.store_translations(:en, nuntius: {events: {user: {activate: "activated"}}})
    get "/nuntius/admin/templates/new", params: {transport: "sms"}

    assert_includes css_select("select[name='template[klass]'] option").map(&:text), "Custom event"
    assert_includes response.body, "activated"
    assert_includes response.body, "Send via"
    assert_equal ["an event", "a time"], css_select("select[name='template[based_on]'] option").map(&:text)
    assert_select ".nuntius-sentence .nuntius-sentence__on", text: "on"
    assert_select ".nuntius-sentence .nuntius-sentence__when", text: "when"
  ensure
    I18n.reload!
  end

  test "a template keeps a class that isn't nuntiable (any more)" do
    template = Nuntius::Template.new(description: "Absent", klass: "Attendance", event: "absent_personal", transport: "mail", account: accounts(:one))
    template.save!(validate: false)

    get "/nuntius/admin/templates/#{template.id}/edit"

    assert_equal "Attendance", css_select("select[name='template[klass]'] option[selected]").first["value"]
    event = css_select("select[name='template[event]'] option[data-chain='Attendance']").first
    assert_equal "absent_personal", event["value"]
    assert_equal "absent personal", event.text
  end

  test "the default transport is mail when it's enabled, or the first" do
    config = Nuntius::Configuration.new
    assert_nil config.default_transport

    config.transport :sms
    assert_equal "sms", config.default_transport

    config.transport :mail
    assert_equal "mail", config.default_transport
  end

  test "a time based template says whom it sends to now, with its limit" do
    travel_to Time.zone.local(2027, 3, 10, 10) do
      User.create!(name: "Juliet", email: "juliet@example.org", born_on: Date.new(1990, 3, 10), account: accounts(:one))
      template = Nuntius::Template.create!(description: "Birthday", klass: "User", event: "before_born_on", interval: "0 days", recurrence: "yearly", transport: "sms", account: accounts(:one))
      event = Nuntius::Template.create!(description: "Activated", klass: "User", event: "activate", transport: "sms", account: accounts(:one))

      get "/nuntius/admin/templates/#{template.id}/edit"
      assert_select "[role=status]", text: /Sends to 1 today/
      assert_select "input[name='template[timebased_limit]'][placeholder='#{Nuntius.config.timebased_limit}']"

      template.update!(timebased_limit: 1)
      User.create!(name: "Romeo", email: "romeo@example.org", born_on: Date.new(1991, 3, 10), account: accounts(:one))
      get "/nuntius/admin/templates/#{template.id}/edit"
      assert_select "[role=status] .text-red-600", text: /more than 1, so it's held/

      get "/nuntius/admin/templates/#{event.id}/edit"
      assert_select "input[name='template[timebased_limit]']", count: 0
    end
  end
end
