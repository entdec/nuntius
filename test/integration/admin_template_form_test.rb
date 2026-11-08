# frozen_string_literal: true

require "test_helper"

# The template form reads as a sentence: send via [mail] when [a user] [is activated]
class AdminTemplateFormTest < ActionDispatch::IntegrationTest
  test "new templates are sent by mail, and transports are in alphabetical order" do
    assert_equal "mail", Nuntius::Template.new.transport

    get "/nuntius/admin/templates/new"

    assert_response :success
    options = css_select("select[name='template[transport]'] option")
    assert_equal options.map(&:text), options.map(&:text).sort_by(&:downcase)
    assert_equal "mail", css_select("select[name='template[transport]'] option[selected]").first["value"]
    assert_includes options.map(&:text), "Email"
  end

  test "the classes and events by their names for people" do
    I18n.backend.store_translations(:en, nuntius: {events: {user: {activate: "is activated"}}})
    get "/nuntius/admin/templates/new"

    assert_includes css_select("select[name='template[klass]'] option").map(&:text), "Custom event"
    assert_includes response.body, "is activated"
    assert_includes response.body, "Send via"
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
end
