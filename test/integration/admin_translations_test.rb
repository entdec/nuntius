# frozen_string_literal: true

require "test_helper"

# The translations a design's t filters use, for the email editor and the
# Translations tab (see Nuntius::Translations)
class AdminTranslationsTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  setup do
    @template = nuntius_templates(:two_recipients_with_translations)
  end

  def url(record = @template)
    "/nuntius/admin/#{record.model_name.route_key.delete_prefix("nuntius_")}/#{record.id}/translations"
  end

  test "the languages, the keys asked for and the ones to suggest" do
    get url, params: {keys: ".greeting,nuntius.transports.mail,.unknown"}, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal %w[en nl], body["locales"]
    assert_equal %w[.greeting .subject], body["suggestions"]
    greeting = body.dig("translations", ".greeting")
    assert_equal "Hoi", greeting.dig("nl", "value")
    assert_equal "Locale nl, account.translationtest.mail.greeting", greeting.dig("nl", "source")
    assert_equal "/nuntius/admin/locales/#{nuntius_locales(:nl).id}/edit", greeting.dig("nl", "url")
    assert_equal "Smurrefluts", body.dig("translations", ".subject", "nl", "value")
    assert_equal "Email", body.dig("translations", "nuntius.transports.mail", "en", "value")
    assert_nil body.dig("translations", "nuntius.transports.mail", "en", "url")
    assert_equal({"en" => nil, "nl" => nil}, body.dig("translations", ".unknown"))
  end

  test "saves a text" do
    patch url, params: {key: ".thanks", locale: "nl", value: "Bedankt"}, as: :json

    assert_response :success
    assert_equal "Bedankt", response.parsed_body.dig("translation", "nl", "value")
    assert_nil response.parsed_body.dig("translation", "en")
    assert_equal "Bedankt", nuntius_locales(:nl).reload.data.dig("nl", "account", "translationtest", "mail", "thanks")
  end

  test "says why it can't save one" do
    patch url, params: {key: "not a key", locale: "nl", value: "x"}, as: :json

    assert_response :unprocessable_content
    assert_match "not a key", response.parsed_body["errors"].first
  end

  test "a layout's and a campaign's are in the layout's scope" do
    layout = create_layout.tap { |layout| layout.update!(name: "Basic Mail") }
    Nuntius::Locale.create!(account: accounts(:one), key: "layout", data: {"en" => {"basic_mail" => {"footer" => "Bye"}}})
    campaign = nuntius_campaigns(:xmas)
    campaign.update_columns(layout_id: layout.id)

    [layout, campaign].each do |record|
      get url(record), as: :json
      assert_equal [".footer"], response.parsed_body["suggestions"]
      assert_equal "Bye", response.parsed_body.dig("translations", ".footer", "en", "value")
    end
  end

  test "the Translations tab lists the keys with their texts, and the editor gets the endpoint" do
    layout = create_layout
    template = Nuntius::Template.create!(description: "Order", klass: "Custom", event: "order#placed", transport: "mail", layout: layout,
      subject: "{{ '.subject' | t }}")
    Nuntius::Locale.create!(account: accounts(:one), key: "order", data: {"nl" => {layout.translation_scope => {"subject" => "Je bestelling"}}})

    get "/nuntius/admin/templates/#{template.id}/edit"

    assert_response :success
    assert_select "[data-controller='tess-edit'][data-tess-edit-translations-url-value=?]", url(template)
    assert_select "[data-controller='nuntius--translations'][data-nuntius--translations-url-value=?]", url(template) do
      assert_select "td", text: ".subject"
      assert_select "input[data-key='.subject'][data-locale='nl'][value='Je bestelling']"
      assert_select "input[data-key='.subject'][data-locale='en']:not([value])"
    end
  end
end
