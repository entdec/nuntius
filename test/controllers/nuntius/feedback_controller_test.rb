# frozen_string_literal: true

require "test_helper"

module Nuntius
  class FeedbackControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      Nuntius::Webhook.create!(provider: "lettermint", external_id: "wh-1", secret: "whsec_secret")
      @message = Nuntius::Message.create!(transport: "mail", state: :sent)
      @body = {
        id: SecureRandom.uuid,
        event: "message.delivered",
        timestamp: Time.current.iso8601,
        data: {message_id: "lm-1", headers: [{name: "X-Nuntius-Message-Id", value: @message.id}]}
      }.to_json
    end

    test "processes a correctly signed lettermint webhook" do
      post_lettermint(@body, signed_headers(@body))

      assert_response :ok
      assert_equal "delivered", @message.reload.state
    end

    test "rejects an invalid signature" do
      post_lettermint(@body, signed_headers(@body, secret: "whsec_wrong"))

      assert_response :bad_request
      assert_equal "sent", @message.reload.state
    end

    test "rejects a tampered body" do
      post_lettermint(@body.sub("delivered", "hard_bounced"), signed_headers(@body))

      assert_response :bad_request
    end

    test "rejects a stale timestamp" do
      post_lettermint(@body, signed_headers(@body, timestamp: 10.minutes.ago.to_i))

      assert_response :bad_request
    end

    test "rejects a missing signature" do
      post_lettermint(@body, {})

      assert_response :bad_request
    end

    private

    def post_lettermint(body, headers)
      post lettermint_feedback_path, params: body, headers: headers.merge("Content-Type" => "application/json")
    end

    def signed_headers(body, secret: "whsec_secret", timestamp: Time.now.to_i)
      signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}")
      {"X-Lettermint-Signature" => "t=#{timestamp},v1=#{signature}", "X-Lettermint-Delivery" => timestamp.to_s}
    end
  end
end
