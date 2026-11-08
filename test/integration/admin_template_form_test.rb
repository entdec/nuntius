# frozen_string_literal: true

require "test_helper"

# The template form reads as a sentence: send via [mail] when on [a user] [activated]
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
    I18n.backend.store_translations(:en, nuntius: {events: {user: {activate: "activated"}}})
    get "/nuntius/admin/templates/new"

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
