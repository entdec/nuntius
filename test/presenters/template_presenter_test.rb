# frozen_string_literal: true

require "test_helper"

# A subclass named as its parent (an STI class whose model_name is its
# parent's) is its parent to people, and its messages use its parent's
# templates too: the template form offers its parent only
class TemplatePresenterTest < ActiveSupport::TestCase
  class NamedAsUser < User
    def self.model_name = User.model_name
  end

  class Admin < User
    def self.model_name = ActiveModel::Name.new(self, nil, "Admin")
  end

  NAMES = ["User", "TemplatePresenterTest::NamedAsUser", "TemplatePresenterTest::Admin"]

  test "the classes to choose from leave out a subclass named as its parent" do
    Nuntius.config.stub(:nuntiable_class_names, NAMES) do
      options = TemplatePresenter.new(Nuntius::Template.new).klass_options
      assert_equal ["TemplatePresenterTest::Admin", "User"], options.map(&:last).sort
    end
  end

  test "a template of such a subclass still has it, so saving keeps it" do
    Nuntius.config.stub(:nuntiable_class_names, NAMES) do
      options = TemplatePresenter.new(Nuntius::Template.new(klass: "TemplatePresenterTest::NamedAsUser")).klass_options
      assert_includes options.map(&:last), "TemplatePresenterTest::NamedAsUser"
    end
  end
end
