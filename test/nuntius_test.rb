# frozen_string_literal: true

require 'test_helper'

class Nuntius::Test < ActiveSupport::TestCase
  # test 'truth' do
  #   assert_kind_of Module, Nuntius
  # end

  test 'adding attachments' do
    messenger = Nuntius::CustomMessenger.new("test", :test)

    attachment = messenger.attach("https://google.com")
    assert_equal 'attachment.html', attachment[:filename]
    assert_equal 'text/html; charset=ISO-8859-1', attachment[:content_type]

    attachment = messenger.attach(nil, content: StringIO.new('test'), filename: 'test.pdf')
    assert_equal 'test.pdf', attachment[:filename]
    assert_equal 'application/pdf', attachment[:content_type]
  end
end
