# frozen_string_literal: true

require "test_helper"

module Nuntius
  # A campaign in a layout built from the Nuntius blocks
  # (test/fixtures/files/nuntius_blocks_layout.mjml, written by npm test).
  class DeliverCampaignServiceTest < ActiveSupport::TestCase
    include EmailDesignHelper
    include ActiveJob::TestHelper

    def blocks_layout
      Layout.create!(name: "Blocks", json: layout_json, mjml: file_fixture("nuntius_blocks_layout.mjml").read)
    end

    def design_in(layout, text)
      content = "<mj-section><mj-column><mj-text>#{text}</mj-text></mj-column></mj-section>"
      {document: EmailDesign.document_with(layout_json, [], subject: "News for {{ subscriber.first_name }}").to_json, mjml: EmailDesign.merge(layout.mjml, content)}
    end

    def campaign_in(layout, text: "Hi {{ subscriber.first_name }}", list: nuntius_lists(:valentines))
      campaign = Campaign.new(name: "News", transport: "mail", list: list, layout: layout)
      campaign.assign_design(**design_in(layout, text))
      campaign
    end

    test "a campaign's message has the subscriber's link and the message's URL" do
      campaign = campaign_in(blocks_layout)
      campaign.state = "sending"
      campaign.save!
      subscriber = nuntius_subscribers(:romeo)

      Mail::TestMailer.deliveries.clear
      perform_enqueued_jobs { DeliverCampaignService.perform(campaign: campaign) }

      message = campaign.messages.find_by!(subscriber: subscriber)
      assert_includes message.html, "Hi Romeo"
      assert_includes message.html, %(href="#{subscriber.url(message)}")
      assert_includes message.html, "Had enough?"
      # The Liquid leaves {{message_url}} alone; the mail provider fills it in
      mail = Mail::TestMailer.deliveries.last
      assert_includes mail.html_part.body.decoded, %(href="#{Nuntius::Engine.routes.url_helpers.message_url(message.id, host: Nuntius.config.host(message))}")
      assert_includes message.html, "<title>News for Romeo</title>"
      assert campaign.reload.sent?
    end

    test "a template has no subscriber, so its Manage subscription block shows nothing" do
      template = Template.new(description: "Order", klass: "Custom", event: "order#placed", transport: "mail", to: "test@example.com", layout: blocks_layout)
      template.assign_design(**design_in(template.layout, "Your order"))
      template.save!

      html = template.new_messages({}).first.html

      assert_includes html, "Your order"
      assert_not_includes html, "Had enough?"
    end

    test "a campaign needs a Manage subscription block when its list lets subscribers unsubscribe" do
      layout = Layout.create!(name: "Plain", json: layout_json, mjml: layout_mjml.sub(%(<a href="{{ subscriber_url }}">Manage your subscription</a>), ""))

      campaign = campaign_in(layout)
      assert_not campaign.valid?
      assert_includes campaign.errors.full_messages.to_sentence, "Add a Manage subscription block"

      nuntius_lists(:valentines).update_column(:allow_unsubscribe, false)
      assert campaign_in(layout).valid?
      assert campaign_in(blocks_layout, list: nuntius_lists(:helpers)).valid?
    end

    test "a campaign only has messages for the subscribers who meet its conditions" do
      list = nuntius_lists(:valentines)
      juliet = list.subscribers.create!(email: "juliet@example.com", first_name: "Juliet")
      campaign = campaign_in(blocks_layout, list: list)
      campaign.conditions = {"match" => "all", "rules" => {"0" => {"variable" => "subscriber.first_name", "operator" => "is", "value" => "juliet"}}}
      campaign.state = "sending"
      campaign.save!

      perform_enqueued_jobs { DeliverCampaignService.perform(campaign: campaign) }

      assert_equal [juliet], campaign.messages.map(&:subscriber)
    end

    test "a test goes to the list's test recipients, whatever the conditions, as often as needed" do
      list = nuntius_lists(:valentines)
      juliet = list.subscribers.create!(email: "juliet@example.com", first_name: "Juliet", test_recipient: true)
      list.subscribers.create!(email: "tybalt@example.com", first_name: "Tybalt", test_recipient: true, unsubscribed_at: Time.current)
      campaign = campaign_in(blocks_layout, list: list)
      campaign.conditions = {"match" => "all", "rules" => {"0" => {"variable" => "subscriber.first_name", "operator" => "is", "value" => "romeo"}}}
      campaign.save!

      Mail::TestMailer.deliveries.clear
      perform_enqueued_jobs { 2.times { campaign.send_test } }

      assert_equal [juliet, juliet], campaign.test_messages.map(&:subscriber)
      assert_equal ["[Test] News for Juliet"] * 2, Mail::TestMailer.deliveries.map(&:subject)
      assert_empty campaign.messages
      assert campaign.reload.draft?
    end
  end
end
