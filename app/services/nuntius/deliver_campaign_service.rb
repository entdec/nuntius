# frozen_string_literal: true

module Nuntius
  class DeliverCampaignService < ApplicationService
    context do
      attribute :campaign
      # Only to the list's test recipients, whatever the conditions, leaving the
      # campaign as it is
      attribute :test_only, default: false
      attribute :messages, default: -> { [] }
      validates :campaign, presence: true
    end

    delegate :campaign, :test_only, :messages, to: :context

    def perform
      return deliver_test if test_only

      deliver
      campaign.sent! if campaign.sending?
    end

    def deliver_test
      transporter = BaseTransport.class_from_name(campaign.transport).new
      campaign.list.subscribers.test_recipients.each do |subscriber|
        messages << new_message(subscriber)
        transporter.deliver(messages.last)
      end
    end

    def deliver
      transporter = BaseTransport.class_from_name(campaign.transport).new
      campaign.list.subscribers.subscribed.each do |subscriber|
        break if campaign.reload.cancelled?
        next unless campaign.conditions_met?(assigns_for(subscriber))

        transporter.deliver(new_message(subscriber))
      end
    end

    def new_message(subscriber, assigns = {})
      message = Nuntius::Message.create!(transport: campaign.transport, campaign: campaign, account: campaign.account, nuntiable: subscriber.nuntiable, subscriber: subscriber, test_message: test_only)

      assigns = assigns.merge(assigns_for(subscriber))
      assigns["subscriber_url"] = subscriber.url(message)

      locale = nil
      if subscriber.nuntiable
        locale_proc = Nuntius::BaseMessenger.messenger_for_obj(subscriber.nuntiable).locale
        locale = instance_exec(subscriber.nuntiable, &locale_proc) if locale_proc
      end

      message.from = render(:from, assigns, locale, message: message)
      message.to = case campaign.transport
      when "mail"
        subscriber.email
      when "sms"
        subscriber.phone_number
      when "voice"
        subscriber.phone_number
      end

      message.subject = render(:subject, assigns, locale, message: message)
      message.subject = "[Test] #{message.subject}" if test_only
      message.html = render(:html, assigns, locale, message: message, layout: campaign.old_layout&.data)

      message.save!
      message
    end

    # The Liquid variables of a subscriber's message, but its subscriber_url:
    # the campaign, the subscriber and its nuntiable (see Campaign#variable_roots)
    def assigns_for(subscriber)
      assigns = {"campaign" => campaign, "subscriber" => subscriber}
      assigns[Nuntius::BaseMessenger.liquid_variable_name_for(subscriber.nuntiable)] = subscriber.nuntiable if subscriber.nuntiable
      assigns
    end

    private

    def render(attr, assigns, locale, message:, **options)
      I18n.with_locale(locale) do
        ::Liquidum.render(campaign.public_send(attr), {assigns: assigns.merge("campaign" => campaign), registers: {"campaign" => campaign, "message" => message}}.merge(options))
      end
    end
  end
end
