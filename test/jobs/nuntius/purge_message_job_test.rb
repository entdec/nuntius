# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class PurgeMessageJobTest < ActiveSupport::TestCase
    test 'does not purge nuntius message less than 6 month ago' do
      account_id = SecureRandom.uuid
      message = Nuntius::Message.create!(transport: 'mail', provider: 'smtp', status: 'sent', metadata: { account_id: account_id }, created_at: 1.month.ago)

      PurgeMessageJob.perform_now(account_id, 6)

      assert message.reload
    end

    test 'purges nuntius message more than 6 month ago' do
      account_id = SecureRandom.uuid
      message = Nuntius::Message.create!(transport: 'mail', provider: 'smtp', status: 'sent', metadata: { account_id: account_id }, created_at: 7.month.ago)

      PurgeMessageJob.perform_now(account_id, 6)

      assert_raises ActiveRecord::RecordNotFound do
        message.reload
      end
    end
  end
end
