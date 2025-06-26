# frozen_string_literal: true

require "test_helper"

module Nuntius
  class MailAllowListTest < ActiveSupport::TestCase
    test "anything is allowed when the list is empty" do
      mail_allow_list = MailAllowList.new
      assert mail_allow_list.allowed?("mark@boxture.com")
      assert mail_allow_list.allowed?("anybody@example.com")
      assert mail_allow_list.allowed?("ivo@bratelement.com")
      assert mail_allow_list.allowed?("andre@itsmeij.com")
    end

    test "passing an empty value does not break the empty list behaviour" do
      mail_allow_list = MailAllowList.new(nil)
      assert mail_allow_list.allowed?("mark@boxture.com")
      assert mail_allow_list.allowed?("anybody@example.com")

      mail_allow_list = MailAllowList.new("")
      assert mail_allow_list.allowed?("ivo@bratelement.com")
      assert mail_allow_list.allowed?("andre@itsmeij.com")
    end

    test "exact e-mail address matching" do
      mail_allow_list = MailAllowList.new(["mark@boxture.com"])

      assert mail_allow_list.allowed?("mark@boxture.com")
      assert mail_allow_list.allowed?("Mark@boxture.com")
      refute mail_allow_list.allowed?("tom@boxture.com")
      refute mail_allow_list.allowed?("mark@example.com")
      refute mail_allow_list.allowed?("ivo@bratelement.com")
      refute mail_allow_list.allowed?("andre@itsmeij.com")
    end

    test "domain matching" do
      mail_allow_list = MailAllowList.new(["boxture.com"])

      assert mail_allow_list.allowed?("mark@boxture.com")
      assert mail_allow_list.allowed?("Mark@boxture.com")
      assert mail_allow_list.allowed?("tom@boxture.com")
      refute mail_allow_list.allowed?("mark@example.com")
      refute mail_allow_list.allowed?("ivo@bratelement.com")
      refute mail_allow_list.allowed?("andre@itsmeij.com")
    end

    test "all together now" do
      mail_allow_list = MailAllowList.new(["boxture.com", "mark@example.com", "degrunt.net"])

      assert mail_allow_list.allowed?("mark@boxture.com")
      assert mail_allow_list.allowed?("tom@boxture.com")
      assert mail_allow_list.allowed?("mark@example.com")
      refute mail_allow_list.allowed?("tom@example.com")
      assert mail_allow_list.allowed?("tom@degrunt.net")
      assert mail_allow_list.allowed?("example@degrunt.net")
      refute mail_allow_list.allowed?("ivo@bratelement.com")
      refute mail_allow_list.allowed?("andre@itsmeij.com")
    end
  end
end
