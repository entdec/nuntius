# frozen_string_literal: true

# Makes sure a webhook exists with Lettermint that delivers message status events to Nuntius, see:
# https://lettermint.co/docs/api-reference/team/webhook
#
# The webhook id and its signing secret are stored in Nuntius::Webhook. Lettermint only returns the secret when a
# webhook is created or its secret is regenerated, so when we find a matching webhook without knowing its secret,
# the secret is regenerated.
module Nuntius
  class LettermintWebhookSetupService < ApplicationService
    API_URL = "https://api.lettermint.co/v1/"
    PROVIDER = "lettermint"

    # Lettermint events we subscribe to and the message state they result in, opens/clicks only update tracking
    STATES = {
      "message.sent" => :sent,
      "message.delivered" => :delivered,
      "message.hard_bounced" => :bounced,
      "message.soft_bounced" => :soft_bounced,
      "message.spam_complaint" => :complaint,
      "message.failed" => :undelivered,
      "message.suppressed" => :blocked,
      "message.policy_rejected" => :rejected
    }.freeze
    EVENTS = (STATES.keys + %w[message.opened message.clicked]).freeze

    def perform
      return unless settings

      # Multiple processes may boot at the same time, make sure only one creates the webhook
      Nuntius::Webhook.connection.execute("SELECT pg_advisory_xact_lock(#{Zlib.crc32("nuntius_lettermint_webhook")})")

      webhook = Nuntius::Webhook.find_or_initialize_by(provider: PROVIDER)

      remote = fetch_webhook(webhook.external_id) if webhook.external_id.present?
      remote ||= find_webhook_by_url

      if remote.nil?
        Nuntius.config.logger.info("Lettermint: creating webhook for #{url}")
        remote = create_webhook
      else
        remote = update_webhook(remote["id"]) unless up_to_date?(remote)

        if webhook.secret.blank? || webhook.external_id != remote["id"]
          Nuntius.config.logger.info("Lettermint: regenerating secret for webhook #{remote["id"]}")
          remote = regenerate_secret(remote["id"])
        end
      end

      webhook.external_id = remote["id"]
      webhook.secret = remote["secret"] if remote["secret"].present?
      webhook.url = url
      webhook.save!
    end

    private

    def desired_attributes
      {
        name: settings[:name],
        url: url,
        events: EVENTS,
        enabled: true,
        scope: settings[:route_id] ? "route" : "project",
        project_ids: settings[:route_id] ? [] : [settings[:project_id]],
        route_ids: settings[:route_id] ? [settings[:route_id]] : []
      }
    end

    def up_to_date?(remote)
      desired = desired_attributes
      remote["url"] == desired[:url] &&
        remote["enabled"] == true &&
        remote["scope"] == desired[:scope] &&
        remote["events"].to_a.sort == desired[:events].sort &&
        remote["project_ids"].to_a.sort == desired[:project_ids].sort &&
        remote["route_ids"].to_a.sort == desired[:route_ids].sort
    end

    def fetch_webhook(id)
      response = client.get("webhooks/#{id}")
      return nil if response.status == 404

      unwrap(check!(response))
    end

    def find_webhook_by_url
      params = {"filter[project]" => settings[:project_id], "page[size]" => 100}
      params["filter[route_id]"] = settings[:route_id] if settings[:route_id]

      loop do
        body = check!(client.get("webhooks", params)).body
        found = body["data"].to_a.find { |webhook| webhook["url"] == url }
        return found if found
        return nil if body["next_cursor"].blank?

        params["cursor"] = body["next_cursor"]
      end
    end

    def create_webhook
      unwrap(check!(client.post("webhooks", desired_attributes)))
    end

    def update_webhook(id)
      unwrap(check!(client.put("webhooks/#{id}", desired_attributes)))
    end

    def regenerate_secret(id)
      unwrap(check!(client.post("webhooks/#{id}/regenerate-secret")))
    end

    def unwrap(response)
      (response.body.is_a?(Hash) && response.body.key?("data")) ? response.body["data"] : response.body
    end

    def check!(response)
      return response if response.success?

      request = "#{response.env.method.to_s.upcase} #{response.env.url.path}"
      raise Nuntius::Error, "Lettermint API request #{request} failed (#{response.status}): #{response.body}"
    end

    def url
      @url ||= begin
        host = settings[:host] || Nuntius.config.host(nil)
        raise Nuntius::Error, "Lettermint webhook needs a host, set host: in config.lettermint_webhook or config.host" if host.blank?

        options = {host: host}
        options[:protocol] = "https" unless host.to_s.include?("://")
        Nuntius::Engine.routes.url_helpers.lettermint_feedback_url(**options)
      end
    end

    def client
      @client ||= Faraday.new(url: API_URL) do |builder|
        builder.request :authorization, "Bearer", settings[:api_token]
        builder.request :json
        builder.response :json
        builder.headers["Accept"] = "application/json"
      end
    end

    def settings
      Nuntius.config.lettermint_webhook_settings
    end
  end
end
