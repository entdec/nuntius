# frozen_string_literal: true

require "test_helper"

class Nuntius::Test < ActiveSupport::TestCase
  test "adding attachments" do
    skip

    messenger = Nuntius::CustomMessenger.new("test", :test)

    VCR.use_cassette("google_dot_com", match_requests_on: [:body]) do
      attachment = messenger.attach(url: "http://google.com")
      assert_equal "attachment.html", attachment[:filename]
      assert_equal "text/html; charset=ISO-8859-1", attachment[:content_type]
    end

    VCR.use_cassette("google_dot_com", match_requests_on: [:body]) do
      attachment = messenger.attach(url: "http://google.com", filename: "example.txt")
      assert_equal "example.txt", attachment[:filename]
      assert_equal "text/html; charset=ISO-8859-1", attachment[:content_type]
    end

    VCR.use_cassette("boxture_logo_with_content_disposition", match_requests_on: [:body]) do
      attachment = messenger.attach(url: "https://www.boxture.com/assets/images/logo.png")
      assert_equal "boxture_logo.png", attachment[:filename]
      assert_equal "image/png", attachment[:content_type]
    end

    VCR.use_cassette("boxture_logo_with_content_disposition", match_requests_on: [:body]) do
      attachment = messenger.attach(url: "https://www.boxture.com/assets/images/logo.png", filename: "box.png")
      assert_equal "box.png", attachment[:filename]
      assert_equal "image/png", attachment[:content_type]
    end

    attachment = messenger.attach(content: StringIO.new("test"), filename: "test.pdf")
    assert_equal "test.pdf", attachment[:filename]
    assert_equal "application/pdf", attachment[:content_type]
  end

  test "messenger for superclass" do
    assert_nothing_raised do
      Nuntius.event(:created, StiChild.create)
    end
  end

  test "check liquid variable names" do
    assert_equal "sti_bases", StiBaseMessenger.liquid_variable_name_for([StiChild.new])
    assert_equal "sti_base", StiBaseMessenger.liquid_variable_name_for(StiChild.new)
    assert_equal "accounts", StiBaseMessenger.liquid_variable_name_for([Account.new])
    assert_equal "account", StiBaseMessenger.liquid_variable_name_for(Account.new)
  end

  test "returns whether there are templates" do
    user = User.create!(name: "test", email: "test@example.com")
    assert Nuntius.templates?(user, :create)
  end
end
