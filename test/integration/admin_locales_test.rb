# frozen_string_literal: true

require "test_helper"

class AdminLocalesTest < ActionDispatch::IntegrationTest
  test "updating a locale and continuing shows its form again" do
    locale = nuntius_locales(:en)

    patch "/nuntius/admin/locales/#{locale.id}", params: {commit: "continue", locale: {key: "en", data_yaml: "en:\n  greeting: Hello\n"}}
    follow_redirect! while response.redirect?

    assert_response :success
    assert_equal "/nuntius/admin/locales/#{locale.id}/edit", path
    assert_equal({"en" => {"greeting" => "Hello"}}, locale.reload.data)
  end
end
