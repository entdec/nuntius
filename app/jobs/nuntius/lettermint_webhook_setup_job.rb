# frozen_string_literal: true

# Checks the Lettermint webhook is set up correctly and creates it when missing, enqueued on server start
module Nuntius
  class LettermintWebhookSetupJob < ApplicationJob
    def perform
      return unless Nuntius::Webhook.table_exists?

      Nuntius::LettermintWebhookSetupService.perform
    end
  end
end
