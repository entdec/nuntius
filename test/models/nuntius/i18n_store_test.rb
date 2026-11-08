# frozen_string_literal: true

require "test_helper"

module Nuntius
  # The `t` filter with the locales of the template's or campaign's account
  # (see test/dummy/config/initializers/liquidum.rb)
  class I18nStoreTest < ActiveSupport::TestCase
    def translate(liquid, registers)
      Liquidum.render(liquid, registers: registers)
    end

    test "a key starting with a dot is in the template's scope" do
      template = nuntius_templates(:two_recipients_with_translations)

      assert_equal "Hoi / Hello", translate("{{ '.greeting' | t: locale: 'nl' }} / {{ '.greeting' | t: locale: 'en' }}", "template" => template)
    end

    test "a key starting with a dot is looked up towards the root, with its arguments" do
      template = nuntius_templates(:two_recipients_with_translations)
      Locale.create!(account: accounts(:one), key: "nl-root", data: {"nl" => {"signature" => "Groeten van %{name}"}})

      assert_equal "Groeten van Nuntius", translate("{{ '.signature' | t: name: 'Nuntius', locale: 'nl' }}", "template" => template)
    end

    test "the app's own translations are there too" do
      template = nuntius_templates(:two_recipients_with_translations)

      assert_equal "Email", translate("{{ 'nuntius.transports.mail' | t: locale: 'en' }}", "template" => template)
    end

    test "only the locales of the template's own account" do
      other = Account.create!(name: "two")
      Locale.create!(account: other, key: "nl", data: {"nl" => {"farewell" => "Doei"}})
      template = nuntius_templates(:two_recipients_with_translations)

      assert_includes translate("{{ 'farewell' | t: locale: 'nl' }}", "template" => template), "translation missing"
      assert_equal "Doei", translate("{{ 'farewell' | t: locale: 'nl' }}", "template" => Template.new(account: other))
    end

    test "a campaign translates with its account's locales" do
      campaign = nuntius_campaigns(:xmas)
      Locale.create!(account: campaign.account, key: "en-campaign", data: {"en" => {"nuntius" => {"wishes" => "Merry Christmas"}}})

      assert_equal "Merry Christmas", translate("{{ '.wishes' | t: locale: 'en' }}", "campaign" => campaign)
    end
  end
end
