# frozen_string_literal: true

module Nuntius
  # Nuntius' services: Facio services, with a Facio context whatever the app's own contexts are. Performed, a service
  # gives its context.
  #
  #   Nuntius::DeliverCampaignService.perform(campaign: campaign, test_only: true).messages
  class ApplicationService < Facio::Service
    transactional true

    class << self
      def perform(...)
        super.context
      end

      def context_base_class
        Facio::Context
      end

      # A service without a context of its own has an empty one
      def context_class
        super || context_base_class
      end
    end
  end
end
