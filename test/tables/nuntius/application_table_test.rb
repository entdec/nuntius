# frozen_string_literal: true

require "test_helper"

module Nuntius
  class ApplicationTableTest < ActiveSupport::TestCase
    setup do
      @view = ApplicationController.new.tap { |controller| controller.request = ActionDispatch::TestRequest.create }.view_context
    end

    teardown do
      Nuntius.config.object_path = ->(object) {}
    end

    test "an object of a mounted engine links to its admin page" do
      template = nuntius_templates(:email)

      link = ApplicationTable.object_link(@view, template)

      assert_includes link, %(href="/nuntius/admin/templates/#{template.id}")
    end

    test "an object without a route is its name, not Ruby's" do
      user = User.create!(account: accounts(:one))

      assert_equal "User #{user.id}", ApplicationTable.object_link(@view, user)
    end

    test "config.object_path gives the path" do
      user = User.create!(account: accounts(:one))
      Nuntius.config.object_path = ->(object) { "/users/#{object.id}" }

      assert_includes ApplicationTable.object_link(@view, user), %(href="/users/#{user.id}")
    end
  end
end
