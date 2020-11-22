# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class RetrieveInboundMailServiceTest < ActiveSupport::TestCase
    test 'retrieves new mail' do
      assert_difference 'Nuntius::InboundMessage.count', 20 do
        Nuntius::RetrieveInboundMailService.new({}).call
      end
      last_message = Nuntius::InboundMessage.last
      assert_equal 'pending', last_message.status
      assert_equal 'mail', last_message.transport
      assert_equal 'imap', last_message.provider
      # assert last_message.provider_id
    end
  end
end
