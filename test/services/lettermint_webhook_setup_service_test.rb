# frozen_string_literal: true

require "test_helper"

module Nuntius
  class LettermintWebhookSetupServiceTest < ActiveSupport::TestCase
    API = "https://api.lettermint.co/v1"
    URL = "https://app.example.com/nuntius/feedback/lettermint"

    setup do
      VCR.turn_off!
      WebMock.disable_net_connect!
      @original_settings = Nuntius.config.lettermint_webhook_settings
      Nuntius.config.lettermint_webhook(api_token: "token", project_id: "project-1", host: "app.example.com")
    end

    teardown do
      Nuntius.config.instance_variable_set(:@lettermint_webhook_settings, @original_settings)
      WebMock.reset!
      WebMock.allow_net_connect!
      VCR.turn_on!
    end

    test "creates the webhook when missing" do
      stub_list([])
      create = stub_request(:post, "#{API}/webhooks")
        .with(headers: {"Authorization" => "Bearer token"}, body: hash_including(url: URL, scope: "project", project_ids: ["project-1"], route_ids: [], events: LettermintWebhookSetupService::EVENTS))
        .to_return(json(201, data: remote(secret: "whsec_new"), message: "Created"))

      Nuntius::LettermintWebhookSetupService.perform

      assert_requested create
      webhook = Nuntius::Webhook.find_by(provider: "lettermint")
      assert_equal "wh-1", webhook.external_id
      assert_equal "whsec_new", webhook.secret
      assert_equal URL, webhook.url
    end

    test "uses route scope when a route is given" do
      Nuntius.config.lettermint_webhook(api_token: "token", project_id: "project-1", route_id: "route-1", host: "https://app.example.com")
      stub_request(:get, "#{API}/webhooks").with(query: hash_including("filter" => hash_including("route_id" => "route-1"))).to_return(json(200, data: [], next_cursor: nil))
      create = stub_request(:post, "#{API}/webhooks")
        .with(body: hash_including(scope: "route", project_ids: [], route_ids: ["route-1"]))
        .to_return(json(201, data: remote(scope: "route", project_ids: [], route_ids: ["route-1"], secret: "whsec_new")))

      Nuntius::LettermintWebhookSetupService.perform

      assert_requested create
    end

    test "does nothing when the stored webhook is up to date" do
      Nuntius::Webhook.create!(provider: "lettermint", external_id: "wh-1", secret: "whsec_old", url: URL)
      stub_request(:get, "#{API}/webhooks/wh-1").to_return(json(200, remote))

      Nuntius::LettermintWebhookSetupService.perform

      assert_not_requested :post, %r{#{API}/webhooks}o
      assert_not_requested :put, %r{#{API}/webhooks}o
      assert_equal "whsec_old", Nuntius::Webhook.find_by(provider: "lettermint").secret
    end

    test "updates the webhook when it differs" do
      Nuntius::Webhook.create!(provider: "lettermint", external_id: "wh-1", secret: "whsec_old", url: URL)
      stub_request(:get, "#{API}/webhooks/wh-1").to_return(json(200, remote(enabled: false, events: ["message.delivered"])))
      update = stub_request(:put, "#{API}/webhooks/wh-1").with(body: hash_including(enabled: true)).to_return(json(200, data: remote))

      Nuntius::LettermintWebhookSetupService.perform

      assert_requested update
    end

    test "recreates the webhook when it was deleted at Lettermint" do
      Nuntius::Webhook.create!(provider: "lettermint", external_id: "wh-gone", secret: "whsec_old", url: URL)
      stub_request(:get, "#{API}/webhooks/wh-gone").to_return(status: 404)
      stub_list([])
      stub_request(:post, "#{API}/webhooks").to_return(json(201, data: remote(secret: "whsec_new")))

      Nuntius::LettermintWebhookSetupService.perform

      webhook = Nuntius::Webhook.find_by(provider: "lettermint")
      assert_equal "wh-1", webhook.external_id
      assert_equal "whsec_new", webhook.secret
    end

    test "regenerates the secret of an existing webhook we don't know the secret of" do
      stub_list([remote(id: "wh-other", url: "https://elsewhere.example.com/hook"), remote])
      regenerate = stub_request(:post, "#{API}/webhooks/wh-1/regenerate-secret").to_return(json(200, data: remote(secret: "whsec_regenerated")))

      Nuntius::LettermintWebhookSetupService.perform

      assert_requested regenerate
      assert_equal "whsec_regenerated", Nuntius::Webhook.find_by(provider: "lettermint").secret
    end

    test "raises when the API fails" do
      stub_list([])
      stub_request(:post, "#{API}/webhooks").to_return(json(422, message: "Invalid"))

      assert_raises(Nuntius::Error) { Nuntius::LettermintWebhookSetupService.perform }
    end

    private

    def stub_list(webhooks)
      stub_request(:get, "#{API}/webhooks").with(query: hash_including("filter" => hash_including("project" => "project-1"))).to_return(json(200, data: webhooks, next_cursor: nil))
    end

    def remote(attributes = {})
      {
        id: "wh-1",
        scope: "project",
        project_ids: ["project-1"],
        route_ids: [],
        name: "Nuntius",
        url: URL,
        events: LettermintWebhookSetupService::EVENTS,
        enabled: true
      }.merge(attributes)
    end

    def json(status, body)
      {status: status, body: body.to_json, headers: {"Content-Type" => "application/json"}}
    end
  end
end
