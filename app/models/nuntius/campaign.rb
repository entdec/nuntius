# frozen_string_literal: true

require_relative 'concerns/metadata_scoped'

module Nuntius
  class Campaign < ApplicationRecord
    include MetadataScoped

    belongs_to :list
    belongs_to :layout, optional: true

    def deliver
      t = BaseTransport.class_from_name(transport).new
      t.deliver(new_message)
    end

    def new_message(assigns = {})
      message = Nuntius::Message.new(transport: transport, campaign: self)

      message.from = render(:from, assigns)

      all_recipients = list.subscribers.map do |subscriber|
        if transport == 'mail'
          %("#{subscriber.first_name} #{subscriber.last_name}" <#{subscriber.email}>)
        elsif transport == 'sms'
          subscriber.phone_number
        elsif transport == 'voice'
          subscriber.phone_number
        end
      end.join(',')

      message.to = all_recipients

      message.subject = render(:subject, assigns)
      message.html = render(:html, assigns, layout: layout&.data)
      message.text = render(:text, assigns, layout: layout&.data)

      message
    end

    def render(attr, assigns, options = {})
      ::Liquor.render(send(attr), { assigns: assigns.merge('campaign' => self) }.merge(options))
    end
  end
end
