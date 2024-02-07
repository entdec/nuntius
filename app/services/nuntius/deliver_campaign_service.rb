# frozen_string_literal: true

module Nuntius
  class DeliverCampaignService < ApplicationService
    context do
      attribute :campaign
      validates :campaign, presence: true
    end

    delegate :campaign, to: :context

    def perform
      deliver
      campaign.sent!
    end

    def deliver
      transporter = BaseTransport.class_from_name(campaign.transport).new
      campaign.list.subscribers.subscribed.each do |subscriber|
        transporter.deliver(new_message(subscriber))
      end
    end

    def new_message(subscriber, assigns = {})
      assigns['subscriber'] = subscriber
      if subscriber.nuntiable
        name = Nuntius::BaseMessenger.liquid_variable_name_for(subscriber.nuntiable)
        assigns[name] = subscriber.nuntiable
      end
      message = Nuntius::Message.new(transport: campaign.transport, campaign: campaign, nuntiable: subscriber.nuntiable, metadata: campaign.metadata)

      locale_proc = Nuntius::BaseMessenger.messenger_for_obj(subscriber.nuntiable).locale
      locale = instance_exec(subscriber.nuntiable, &locale_proc) if subscriber.nuntiable && locale_proc

      message.from = render(:from, assigns, locale)
      message.to = case campaign.transport
                  when 'mail'
                    subscriber.email
                  when 'sms'
                    subscriber.phone_number
                  when 'voice'
                    subscriber.phone_number
                  end

      message.subject = render(:subject, assigns, locale)
      message.html = render(:html, assigns, locale, layout: campaign.layout&.data)

      message
    end

    def translation_scope
      scope = %w[nuntius]
      scope << campaign.layout.name.underscore.tr(' ', '_') if layout
      scope.join('.')
    end

    private

    def render(attr, assigns, locale, options = {})
      I18n.with_locale(locale) do
        ::Liquidum.render(campaign.public_send(attr), { assigns: assigns.merge('campaign' => campaign), registers: { 'campaign' => campaign } }.merge(options))
      end
    end
  end
end
