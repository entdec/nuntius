# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class MessageTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    test 'delivering a message will persist it and queue it for delivery' do
      message = nuntius_messages(:hoi)

      perform_enqueued_jobs do
        message.deliver_as(:mail)
        assert message
        assert message.persisted?
        assert_equal 'pending', message.status
        assert_equal 'mail', message.transport
        assert_equal 'smtp', message.reload.provider

        assert_equal 1, Mail::TestMailer.deliveries.length
        mail = Mail::TestMailer.deliveries.first
        assert_equal ['test@example.com'], mail.to
        Mail::TestMailer.deliveries.clear
      end
    end
  end
end
