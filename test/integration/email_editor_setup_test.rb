# frozen_string_literal: true

require "test_helper"

class EmailEditorSetupTest < ActionDispatch::IntegrationTest
  test "the import map has Nuntius' JavaScript and the email editor" do
    imports = JSON.parse(Rails.application.importmap.to_json(resolver: ActionController::Base.helpers))["imports"]

    assert imports.key?("nuntius")
    assert imports.key?("tess_edit")
    assert imports.key?("tess_edit/vendor/tiptap")
  end

  test "the editor compiles through Nuntius, behind its admin authentication" do
    assert_equal Nuntius::ApplicationAdminController, TessEdit::ApplicationController.superclass

    post "/nuntius/tess_edit/compile", params: {mjml: "<mjml><mj-body><mj-text>Hi {{ name }}</mj-text></mj-body></mjml>"}, as: :json

    assert_response :success
    assert_includes response.parsed_body["html"], "Hi {{ name }}"
  end
end
