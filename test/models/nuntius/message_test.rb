# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class MessageTest < ActiveSupport::TestCase
    test 'the truth' do
      a = Account.first

      m = Nuntius::Message.create(to: 'test@example.com', html: '<b>Hoi</b>', text: "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - test", transport: 'mail')
      Nuntius.with(a).message('created')
    end
  end
end
