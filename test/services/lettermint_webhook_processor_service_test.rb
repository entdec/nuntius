# frozen_string_literal: true

require "test_helper"

module Nuntius
  class LettermintWebhookProcessorServiceTest < ActiveSupport::TestCase
    setup do
      @message = Nuntius::Message.create!(transport: "mail", provider_id: "abc123@example.com", state: :sent)
    end

    test "marks a message delivered, matched on the X-Nuntius-Message-Id header" do
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.delivered", response: {status_code: 250}))
      @message.reload
      assert_equal "delivered", @message.state
      assert_equal "delivered", @message.metadata["feedback"]["type"]
      assert_equal 250, @message.metadata["feedback"]["info"]["response"]["status_code"]
      assert_equal "lm-1", @message.metadata["lettermint_message_id"]
    end

    test "marks a pending message sent" do
      @message.update!(state: :pending)
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.sent"))
      assert_equal "sent", @message.reload.state
    end

    test "matches on a previously stored lettermint message id" do
      @message.update!(metadata: {"lettermint_message_id" => "lm-1"})
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.hard_bounced", headers: []))
      assert_equal "bounced", @message.reload.state
    end

    test "matches on the Message-ID header" do
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.spam_complaint", headers: [{name: "Message-ID", value: "<abc123@example.com>"}]))
      assert_equal "complaint", @message.reload.state
    end

    test "maps failure events to message states" do
      {"message.failed" => "undelivered", "message.suppressed" => "blocked", "message.policy_rejected" => "rejected"}.each do |event_type, state|
        @message.update!(state: :sent)
        Nuntius::LettermintWebhookProcessorService.call(event: event(event_type))
        assert_equal state, @message.reload.state
      end
    end

    test "marks a message soft bounced, and delivered once a retry succeeds" do
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.soft_bounced"))
      assert_equal "soft_bounced", @message.reload.state

      Nuntius::LettermintWebhookProcessorService.call(event: event("message.delivered"))
      assert_equal "delivered", @message.reload.state
    end

    test "does not soft bounce a delivered or bounced message" do
      %w[delivered bounced].each do |state|
        @message.update!(state: state)
        Nuntius::LettermintWebhookProcessorService.call(event: event("message.soft_bounced"))
        assert_equal state, @message.reload.state
      end
    end

    test "does not move a delivered message back to sent" do
      @message.update!(state: :delivered)
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.sent"))
      assert_equal "delivered", @message.reload.state
    end

    test "does not mark a bounced message delivered" do
      @message.update!(state: :bounced)
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.delivered"))
      assert_equal "bounced", @message.reload.state
    end

    test "records opens" do
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.opened", opened_at: "2025-08-08T20:17:00+00:00", classification_revision: 1))
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.opened", opened_at: "2025-08-09T20:17:00+00:00", classification_revision: 1))
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.opened", opened_at: "2025-08-09T20:17:00+00:00", classification_revision: 2))
      @message.reload
      assert_equal "sent", @message.state
      assert_equal Time.zone.parse("2025-08-08T20:17:00+00:00"), @message.opened_at
      assert_equal 2, @message.open_count
    end

    test "records clicks" do
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.clicked", clicked_at: "2025-08-08T20:18:30+00:00", destination_url: "https://example.com/product/123"))
      @message.reload
      assert_equal Time.zone.parse("2025-08-08T20:18:30+00:00"), @message.clicked_at
      assert_equal 1, @message.click_count
      assert_equal 1, @message.message_trackings.find_by(url: "https://example.com/product/123").count
    end

    test "ignores unknown messages" do
      Nuntius::LettermintWebhookProcessorService.call(event: event("message.delivered", message_id: "other", headers: []))
      assert_equal "sent", @message.reload.state
    end

    private

    def event(type, data = {})
      {
        id: SecureRandom.uuid,
        event: type,
        timestamp: "2025-08-08T20:15:12.000Z",
        data: {
          message_id: "lm-1",
          subject: "Test",
          recipient: "user@example.com",
          headers: [{name: "x-nuntius-message-id", value: @message.id}],
          metadata: {},
          tag: nil,
          tags: []
        }.merge(data)
      }
    end
  end
end
