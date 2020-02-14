# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class MessageTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    test 'delivering a message will persist it and queue it for delivery' do
      message = nuntius_messages(:one)

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

    test 'delivering a mail to two recipients will deliver separate messages' do
      message = nuntius_messages(:two)

      perform_enqueued_jobs(only: Nuntius::TransportDeliveryJob) do
        message.deliver_as(:mail)
      end
      assert_performed_jobs 2

      assert_equal 2, Mail::TestMailer.deliveries.length
      mail = Mail::TestMailer.deliveries.first
      assert_equal ['test@example.com'], mail.to
      mail = Mail::TestMailer.deliveries.last
      assert_equal ['test2@example.com'], mail.to
      Mail::TestMailer.deliveries.clear
    end
  end
end
