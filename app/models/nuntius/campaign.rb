# frozen_string_literal: true

module Nuntius
  class Campaign < ApplicationRecord
    include Concerns::MetadataScoped

    belongs_to :list
    accepts_nested_attributes_for :list, reject_if: :all_blank

    belongs_to :layout, optional: true
    has_many :messages, class_name: 'Nuntius::Message'
    validates :name, presence: true

    state_machine initial: :draft do
      after_transition any => any, do: :do_after_transition

      event :publish do
        transition draft: :sending
      end
      event :sent do
        transition sending: :sent
      end
    end

    def deliver
      t = BaseTransport.class_from_name(transport).new
      list.subscribers.each do |subscriber|
        t.deliver(new_message(subscriber))
      end
    end

    def new_message(subscriber, assigns = {})
      if subscriber.nuntiable
        name = Nuntius::BaseMessenger.liquid_variable_name_for(subscriber.nuntiable)
        assigns[name] = subscriber.nuntiable
      end
      message = Nuntius::Message.new(transport: transport, campaign: self, nuntiable: subscriber.nuntiable, metadata: metadata)

      locale_proc = Nuntius::BaseMessenger.messenger_for_obj(subscriber.nuntiable).locale
      locale = instance_exec(object, &locale_proc) if locale_proc

      message.from = render(:from, assigns, locale)
      message.to = if transport == 'mail'
                     %("#{subscriber.first_name} #{subscriber.last_name}" <#{subscriber.email}>)
                   elsif transport == 'sms'
                     subscriber.phone_number
                   elsif transport == 'voice'
                     subscriber.phone_number
                   end

      message.subject = render(:subject, assigns, locale)
      message.html = render(:html, assigns, locale, layout: layout&.data)

      message
    end

    def translation_scope
      scope = %w[nuntius]
      scope << layout.name.underscore.tr(' ', '_') if layout
      scope.join('.')
    end

    private

    def render(attr, assigns, locale, options = {})
      I18n.with_locale(locale) do
        ::Liquor.render(send(attr), assigns: assigns.merge(options), registers: { 'campaign' => self })
      end
    end

    def do_after_transition(transition)
      deliver if transition.event == :publish
    end
  end
end
