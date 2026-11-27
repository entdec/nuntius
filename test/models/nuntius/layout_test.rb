# frozen_string_literal: true

require "test_helper"

module Nuntius
  class LayoutTest < ActiveSupport::TestCase
    include EmailDesignHelper

    test "needs a name and a design" do
      assert_not Layout.new.valid?
      assert_not Layout.new(name: "Basic").valid?
      assert Layout.new(name: "Basic", json: layout_json, mjml: layout_mjml).valid?
    end

    Layout::STARTING_LAYOUTS.each do |key|
      test "the #{key} starting layout makes a layout that compiles" do
        document = Layout.starting_document(key)
        mjml = file_fixture("starting_layouts/#{key}.mjml").read

        assert_equal "email", document["type"]
        assert(document.to_json.scan(/"id":"([^"]+)"/).flatten.all? { |id| id.start_with?("b") })
        layout = Layout.create!(name: key, json: document, mjml: mjml)
        assert layout.html.present?
      end
    end

    test "a starting layout's texts are in the current language" do
      document = I18n.with_locale(:nl) { Layout.starting_document("basic") }.to_json

      assert_includes document, "Je naam of logo"
      assert_includes document, "Hier komt de inhoud van elk sjabloon en elke campagne."
      assert_not_includes document, "Your name or logo"
      assert_includes I18n.with_locale(:en) { Layout.starting_document("basic") }.to_json, "Your name or logo"
    end

    # Each text people see in a starting layout is one of its texts, in English
    # and in Dutch (nuntius.starting_layouts.texts)
    Layout::STARTING_LAYOUTS.each do |key|
      test "the #{key} starting layout's texts are all translated" do
        texts = Layout.starting_texts(::JSON.parse(Engine.root.join("config/nuntius/starting_layouts/#{key}.json").read))
        english = I18n.t("nuntius.starting_layouts.texts", locale: :en)
        dutch = I18n.t("nuntius.starting_layouts.texts", locale: :nl)

        assert_empty texts - english.values, key
        assert_equal english.keys.sort, dutch.keys.sort
      end
    end

    test "an unknown starting layout is the basic one" do
      assert_equal Layout.starting_document("basic"), Layout.starting_document("../../secrets")
    end
  end
end
