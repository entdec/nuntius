module Nuntius
  class PurgeMessageJob < ApplicationJob
    def perform(account_id, months)
      messages = Nuntius::Message.distinct.select(:id).where("metadata ->> 'account_id' = :account", account: account_id)
        .where(created_at: ..months.months.ago.beginning_of_day)
        .where.not(status: %w[complaint bounced])

      Nuntius::Message.where(parent_message_id: messages.pluck(:id)).in_batches.update_all(parent_message_id: nil)

      # We use a find_each now because a destroy_all gets bypassed by the `before_destroy :cleanup_attachments` method in message.rb
      messages.find_each(&:destroy)
    end
  end
end
