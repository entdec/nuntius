# frozen_string_literal: true

require 'test_helper'

class Nuntius::Test < ActiveSupport::TestCase
  # test 'truth' do
  #   assert_kind_of Module, Nuntius
  # end

  test 'adding attachments' do
    messenger = Nuntius::CustomMessenger.new("test", :test)

    VCR.use_cassette('google_dot_com', match_requests_on: [:body]) do
      attachment = messenger.attach(url: "http://google.com")
      assert_equal 'attachment.html', attachment[:filename]
      assert_equal 'text/html; charset=ISO-8859-1', attachment[:content_type]
    end

    VCR.use_cassette('google_dot_com', match_requests_on: [:body]) do
      attachment = messenger.attach(url: "http://google.com", filename: 'example.txt')
      assert_equal 'example.txt', attachment[:filename]
      assert_equal 'text/html; charset=ISO-8859-1', attachment[:content_type]
    end

    VCR.use_cassette('boxture_logo_with_content_disposition', match_requests_on: [:body]) do
      attachment = messenger.attach(url: "https://www.boxture.com/assets/images/logo.png")
      assert_equal 'boxture_logo.png', attachment[:filename]
      assert_equal 'image/png', attachment[:content_type]
    end

    VCR.use_cassette('boxture_logo_with_content_disposition', match_requests_on: [:body]) do
      attachment = messenger.attach(url: "https://www.boxture.com/assets/images/logo.png", filename: 'box.png')
      assert_equal 'box.png', attachment[:filename]
      assert_equal 'image/png', attachment[:content_type]
    end

    attachment = messenger.attach(content: StringIO.new('test'), filename: 'test.pdf')
    assert_equal 'test.pdf', attachment[:filename]
    assert_equal 'application/pdf', attachment[:content_type]
  end
end
