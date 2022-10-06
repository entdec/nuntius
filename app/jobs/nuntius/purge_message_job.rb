module Nuntius
  class PurgeMessageJob < ApplicationJob
    def perform(account_id, months)
      messages = Nuntius::Message.distinct.select(:id).where("metadata ->> 'account_id' = :account", account: account_id)
        .where(created_at: ..months.months.ago.beginning_of_day)

      messages.in_batches.destroy_all
    end
  end
end
