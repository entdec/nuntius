# frozen_string_literal: true

require "test_helper"

module Nuntius
  # What a template's t filters say in each language, and saving them (see
  # test/fixtures/nuntius/locales.yml)
  class TranslationsTest < ActiveSupport::TestCase
    setup do
      @template = nuntius_templates(:two_recipients_with_translations)
      @translations = Translations.new(@template)
    end

    test "the languages of the account's locales, the default first" do
      Locale.create!(account: accounts(:one), key: "de", data: {"de" => {"hello" => "Hallo"}})

      assert_equal %w[en de nl], @translations.locales
    end

    test "the keys its Liquid translates" do
      @template.text = %({{ "order.shipped" | t: name: order.name }} {{ '.greeting' | t }})

      assert_equal %w[.subject .greeting order.shipped], @translations.keys
    end

    test "a key in each language, with where it's kept" do
      texts = @translations.lookup(".greeting")

      assert_equal "Hello", texts["en"].value
      assert_equal "Hoi", texts["nl"].value
      assert_equal nuntius_locales(:nl), texts["nl"].locale_record
      assert_equal "account.translationtest.mail.greeting", texts["nl"].path
      assert_equal "Locale nl, account.translationtest.mail.greeting", texts["nl"].source
    end

    test "looked up towards the root, like the t filter, then in the app's translations" do
      Locale.create!(account: accounts(:one), key: "nl-root", data: {"nl" => {"account" => {"signature" => "Groeten"}}})

      assert_equal "account.signature", @translations.text(".signature", "nl").path
      assert_nil @translations.text(".signature", "en")
      assert_equal "Email", @translations.text("nuntius.transports.mail", "en").value
      assert_nil @translations.text("nuntius.transports.mail", "en").locale_record
    end

    test "later locales win, as when sending" do
      Locale.create!(account: accounts(:one), key: "nl-later", data: {"nl" => {"account" => {"translationtest" => {"mail" => {"greeting" => "Hallo"}}}}})

      assert_equal "Hallo", @translations.text(".greeting", "nl").value
      assert_equal "Hallo", Liquidum.render("{{ '.greeting' | t: locale: 'nl' }}", registers: {"template" => @template})
    end

    test "suggests the keys in its own scope, and those right in the scopes above it" do
      Locale.create!(account: accounts(:one), key: "more", data: {"en" => {"footer" => "Bye", "other" => {"deep" => "No"}, "account" => {"translationtest" => {"mail" => {"order" => {"title" => "Order"}}}}}})

      assert_equal %w[.footer .greeting .order.title .subject], @translations.suggestions
    end

    test "saves a text where it's kept" do
      @translations.save(".greeting", "nl", "Hallo")

      assert_equal "Hallo", nuntius_locales(:nl).reload.data.dig("nl", "account", "translationtest", "mail", "greeting")
      assert_equal "Hallo", Translations.new(@template).text(".greeting", "nl").value
    end

    test "a missing language goes next to its other languages, in the locale named after it" do
      Locale.create!(account: accounts(:one), key: "nl-root", data: {"nl" => {"account" => {"signature" => "Groeten"}}})

      @translations.save(".signature", "en", "Regards")

      assert_equal "Regards", nuntius_locales(:en).reload.data.dig("en", "account", "signature")
    end

    test "a new key goes in its own scope, in a new locale when there's none for the language" do
      Locale.create!(account: accounts(:one), key: "shared", data: {"de" => {}})
      @translations.save(".thanks", "de", "Danke")

      locale = Locale.find_by!(account: accounts(:one), key: "de")
      assert_equal({"de" => {"account" => {"translationtest" => {"mail" => {"thanks" => "Danke"}}}}}, locale.data)
      assert_equal "Danke", Liquidum.render("{{ '.thanks' | t: locale: 'de' }}", registers: {"template" => @template})
    end

    test "an empty text removes it" do
      @translations.save(".greeting", "nl", "")

      assert_nil nuntius_locales(:nl).reload.data.dig("nl", "account", "translationtest", "mail", "greeting")
      assert_equal "Smurrefluts", nuntius_locales(:nl).data.dig("nl", "account", "translationtest", "mail", "subject")
    end

    test "refuses what isn't a key or a language, or would replace other keys" do
      assert_raises(Translations::Error) { @translations.save("not a key", "nl", "x") }
      assert_raises(Translations::Error) { @translations.save(".greeting", "fr", "x") }
      error = assert_raises(Translations::Error) { @translations.save(".greeting.formal", "nl", "x") }
      assert_match "account.translationtest.mail.greeting.formal", error.message
    end

    test "a layout's keys are its templates' and campaigns'" do
      layout = Layout.new(name: "Slimme Groep")
      template = Template.new(layout: layout, klass: "User", event: "activate", transport: "mail", description: "Welcome")
      campaign = Campaign.new(layout: layout)

      assert_equal "slimme_groep", layout.translation_scope
      assert_equal "slimme_groep.user.activate.mail.welcome", template.translation_scope
      assert_equal "slimme_groep", campaign.translation_scope
    end
  end
end
