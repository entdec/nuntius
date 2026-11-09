# frozen_string_literal: true

require "test_helper"

module Nuntius
  class LocaleTest < ActiveSupport::TestCase
    def locale(**attributes)
      Locale.new(account: accounts(:one), key: "extra", data: {"en" => {"hi" => "Hi"}}, **attributes)
    end

    test "its data starts with languages, with translations under them" do
      assert locale(data: {"en" => {"hi" => "Hi"}, "pt-BR" => {"hi" => "Oi"}, "nl" => nil}).valid?

      assert_includes locale(data: {"greeting" => {"hi" => "Hi"}}).tap(&:validate).errors[:data].first, "greeting"
      assert_includes locale(data: {"en" => "Hi"}).tap(&:validate).errors[:data].first, "en:"
      assert locale(data: ["en"]).invalid?
    end

    test "its key is unique in its account" do
      assert locale(key: "nl").invalid?
      assert locale(key: "").invalid?
      assert Locale.new(account: Account.create!(name: "two"), key: "nl", data: {}).valid?
    end

    test "YAML that can't be read is an error, not an exception" do
      record = locale
      record.data_yaml = "en:\n  hi: [Hi"

      assert record.invalid?
      assert_match "not valid YAML", record.errors[:data].first
      assert_equal({"en" => {"hi" => "Hi"}}, record.data)
    end
  end
end
