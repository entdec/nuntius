# frozen_string_literal: true

###
# Process webhook events from Lettermint, see: https://lettermint.co/docs/platform/webhooks/events
#
# Events look like this:
#  {"id"=>"9b0c4a4e-...", "event"=>"message.delivered", "timestamp"=>"2025-08-08T20:15:12.000Z",
#   "data"=>{"message_id"=>"f47ac10b-...", "recipient"=>"user@example.com", "response"=>{...},
#            "headers"=>[{"name"=>"X-Nuntius-Message-Id", "value"=>"..."}], ...}}
#
# Messages are matched on the X-Nuntius-Message-Id header Nuntius adds to every mail, falling back to the Lettermint
# message id we stored earlier and the Message-ID header.
module Nuntius
  class LettermintWebhookProcessorService < ApplicationService
    context do
      attribute :event, typecaster: lambda { |value|
                                      value.with_indifferent_access
                                    }
    end

    def perform
      return if event_type == "webhook.test"

      unless message
        Nuntius.config.logger.warn("Lettermint #{event_type} for unknown message with lettermint id: #{data["message_id"]}")
        return false
      end
      Nuntius.config.logger.info("Lettermint updating message #{message.id} for #{event_type}")

      message.metadata["lettermint_message_id"] = data["message_id"]

      case event_type
      when "message.opened"
        process_open
      when "message.clicked"
        process_click
      else
        process_state
      end

      message.save!
    end

    private

    def process_state
      state = LettermintWebhookSetupService::STATES[event_type]
      return unless state
      # Events can arrive out of order, don't let progress events undo a later state
      return if %i[sent soft_bounced].include?(state) && !(message.pending? || message.sent? || message.soft_bounced?)
      return if state == :delivered && (message.bounced? || message.complaint?)

      message.send(state)
      message.metadata["feedback"] = {type: event_type.delete_prefix("message."), info: data.except(:headers, :metadata, :tag, :tags, :subject)}
    end

    def process_open
      # Higher revisions re-classify an open we've already counted
      return if data["classification_revision"].to_i > 1

      message.opened_at ||= parse_time(data["opened_at"])
      message.open_count = (message.open_count || 0) + 1
    end

    def process_click
      return if data["classification_revision"].to_i > 1

      message.clicked_at ||= parse_time(data["clicked_at"])
      message.click_count = (message.click_count || 0) + 1

      return if data["destination_url"].blank?

      tracking = message.message_trackings.find_or_create_by(url: data["destination_url"])
      tracking.count = (tracking.count || 0) + 1
      tracking.save!
    end

    def parse_time(value)
      Time.zone.parse(value.to_s) || Time.current
    end

    def event_type
      context.event["event"]
    end

    def data
      context.event["data"] || {}
    end

    def header(name)
      data["headers"].to_a.find { |h| h["name"].to_s.casecmp?(name) }&.dig("value")
    end

    def message
      @message ||= find_by_nuntius_id || find_by_lettermint_id || find_by_message_id_header
    end

    def find_by_nuntius_id
      id = header("X-Nuntius-Message-Id")
      Nuntius::Message.find_by(id: id) if id.present?
    end

    def find_by_lettermint_id
      Nuntius::Message.find_by("metadata->>'lettermint_message_id' = ?", data["message_id"]) if data["message_id"].present?
    end

    def find_by_message_id_header
      message_id = header("Message-ID")&.delete("<>")
      Nuntius::Message.find_by(provider_id: message_id) if message_id.present?
    end
  end
end
