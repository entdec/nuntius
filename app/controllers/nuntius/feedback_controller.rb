# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class FeedbackController < ApplicationController
    LETTERMINT_TOLERANCE = 300

    skip_before_action :verify_authenticity_token

    layout false

    def awssns
      Nuntius::AwsSnsProcessorService.perform(notification: ::JSON.parse(request.body.read))
      head :ok
    end

    # See: https://lettermint.co/docs/platform/webhooks/signing
    def lettermint
      body = request.raw_post
      return head(:bad_request) unless valid_lettermint_signature?(body)

      Nuntius::LettermintWebhookProcessorService.perform(event: ::JSON.parse(body))
      head :ok
    end

    private

    def valid_lettermint_signature?(body)
      parts = request.headers["X-Lettermint-Signature"].to_s.split(",").map { |part| part.strip.split("=", 2) }
      timestamp = parts.find { |key, _| key == "t" }&.last
      signatures = parts.filter_map { |key, value| value if key == "v1" }
      return false if timestamp.blank? || signatures.empty?
      return false unless request.headers["X-Lettermint-Delivery"] == timestamp
      return false if (Time.now.to_i - timestamp.to_i).abs > LETTERMINT_TOLERANCE

      secrets = Nuntius::Webhook.where(provider: Nuntius::LettermintWebhookSetupService::PROVIDER).where.not(secret: nil).pluck(:secret)
      secrets.any? do |secret|
        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
        signatures.any? { |signature| ActiveSupport::SecurityUtils.secure_compare(expected, signature) }
      end
    end
  end
end
