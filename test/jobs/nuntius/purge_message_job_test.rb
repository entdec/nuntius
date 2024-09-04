# frozen_string_literal: true

require "test_helper"

module Nuntius
  class PurgeMessageJobTest < ActiveSupport::TestCase
    test "does not purge nuntius message less than 6 month ago" do
      account_id = SecureRandom.uuid
      message = Nuntius::Message.create!(transport: "mail", provider: "smtp", status: "sent", metadata: {account_id: account_id}, created_at: 1.month.ago)

      PurgeMessageJob.perform_now(account_id, 6)

      assert message.reload
    end

    test "purges nuntius message more than 6 month ago" do
      account_id = SecureRandom.uuid
      message = Nuntius::Message.create!(transport: "mail", provider: "smtp", status: "sent", metadata: {account_id: account_id}, created_at: 7.month.ago)

      PurgeMessageJob.perform_now(account_id, 6)

      assert_raises ActiveRecord::RecordNotFound do
        message.reload
      end
    end

    test "does not purge attachments for message less than 6 months ago" do
      account_id = SecureRandom.uuid
      message = Nuntius::Message.create!(transport: "mail", provider: "smtp", status: "sent", metadata: {account_id: account_id}, created_at: 1.month.ago)

      attachment = Nuntius::Attachment.create!
      message.attachments << attachment

      PurgeMessageJob.perform_now(account_id, 6)

      # Reload the message and attachment to ensure they are not deleted
      assert message.reload
      assert attachment.reload
    end

    test "purges attachments for message more than 6 months ago" do
      account_id = SecureRandom.uuid
      message = Nuntius::Message.create!(transport: "mail", provider: "smtp", status: "sent", metadata: {account_id: account_id}, created_at: 7.months.ago)

      attachment = Nuntius::Attachment.create!
      message.attachments << attachment

      PurgeMessageJob.perform_now(account_id, 6)

      # Assert that the message has been destroyed
      assert_raises ActiveRecord::RecordNotFound do
        message.reload
      end

      # Check that the attachment is purged if it is not associated with any other messages
      assert_raises ActiveRecord::RecordNotFound do
        attachment.reload
      end
    end
  end
end
