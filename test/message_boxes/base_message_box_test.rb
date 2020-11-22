# frozen_string_literal: true

require 'test_helper'

class FooMessagebox < Nuntius::BaseMessageBox
  transport :sms
  provider :twilio

  route /\+31.+/ => :dutchies
end

class BarMessagebox < Nuntius::BaseMessageBox
  transport :mail
  provider :imap
end

class Nuntius::BaseMessageBoxTest < ActiveSupport::TestCase
  test 'finds its descendants' do
    assert_equal [BarMessagebox, FooMessagebox], Nuntius::BaseMessageBox.descendants
  end

  test 'finds a message box for transport and provider' do
    assert_equal [FooMessagebox], Nuntius::BaseMessageBox.for(transport: :sms)
    assert_equal [FooMessagebox], Nuntius::BaseMessageBox.for(transport: :sms, provider: :twilio)
    assert_equal [BarMessagebox], Nuntius::BaseMessageBox.for(transport: :mail)
  end

  test 'finds a message box matching a recipient' do
    assert_equal [FooMessagebox, :dutchies], Nuntius::BaseMessageBox.for_route([BarMessagebox, FooMessagebox], %w[+31641085630])
  end

  test 'returns nil for no message box matching a recipient' do
    assert_nil Nuntius::BaseMessageBox.for_route([BarMessagebox, FooMessagebox], %w[+33641085630])
  end
end
