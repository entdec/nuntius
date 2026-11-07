# frozen_string_literal: true

require "test_helper"

module Nuntius
  class MailAllowListTest < ActiveSupport::TestCase
    test "anything is allowed when the list is empty" do
      mail_allow_list = MailAllowList.new
      assert mail_allow_list.allowed?("mark@example.net")
      assert mail_allow_list.allowed?("anybody@example.com")
      assert mail_allow_list.allowed?("ivo@first.example.org")
      assert mail_allow_list.allowed?("andre@second.example.org")
    end

    test "passing an empty value does not break the empty list behaviour" do
      mail_allow_list = MailAllowList.new(nil)
      assert mail_allow_list.allowed?("mark@example.net")
      assert mail_allow_list.allowed?("anybody@example.com")

      mail_allow_list = MailAllowList.new("")
      assert mail_allow_list.allowed?("ivo@first.example.org")
      assert mail_allow_list.allowed?("andre@second.example.org")
    end

    test "exact e-mail address matching" do
      mail_allow_list = MailAllowList.new(["mark@example.net"])

      assert mail_allow_list.allowed?("mark@example.net")
      assert mail_allow_list.allowed?("Mark@example.net")
      refute mail_allow_list.allowed?("tom@example.net")
      refute mail_allow_list.allowed?("mark@example.com")
      refute mail_allow_list.allowed?("ivo@first.example.org")
      refute mail_allow_list.allowed?("andre@second.example.org")
    end

    test "domain matching" do
      mail_allow_list = MailAllowList.new(["example.net"])

      assert mail_allow_list.allowed?("mark@example.net")
      assert mail_allow_list.allowed?("Mark@example.net")
      assert mail_allow_list.allowed?("tom@example.net")
      refute mail_allow_list.allowed?("mark@example.com")
      refute mail_allow_list.allowed?("ivo@first.example.org")
      refute mail_allow_list.allowed?("andre@second.example.org")
    end

    test "all together now" do
      mail_allow_list = MailAllowList.new(["example.net", "mark@example.com", "example.org"])

      assert mail_allow_list.allowed?("mark@example.net")
      assert mail_allow_list.allowed?("tom@example.net")
      assert mail_allow_list.allowed?("mark@example.com")
      refute mail_allow_list.allowed?("tom@example.com")
      assert mail_allow_list.allowed?("tom@example.org")
      assert mail_allow_list.allowed?("example@example.org")
      refute mail_allow_list.allowed?("ivo@first.example.org")
      refute mail_allow_list.allowed?("andre@second.example.org")
    end
  end
end
