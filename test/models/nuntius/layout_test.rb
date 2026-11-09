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

    test "an unknown starting layout is the basic one" do
      assert_equal Layout.starting_document("basic"), Layout.starting_document("../../secrets")
    end
  end
end
