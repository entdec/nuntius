# frozen_string_literal: true

require_relative 'concerns/metadata_scoped'

module Nuntius
  class Template < ApplicationRecord
    include MetadataScoped

    belongs_to :layout, optional: true
    has_many :messages, class_name: 'Nuntius::Message'

    # TODO: attachments - also templates could have attachments

    validates :description, presence: true

    scope :metadata, lambda { |name, value|
      where('metadata->>:name = :value', name: name, value: value)
    }

    def new_message(object, assigns)
      message = Nuntius::Message.new(template: self, transport: transport, nuntiable: object, metadata: metadata)

      message.to = render(:to, assigns)
      message.subject = render(:subject, assigns)
      message.html = render(:html, assigns, layout: layout&.data)
      message.text = render(:text, assigns, layout: layout&.data)

      message
    end

    private

    def render(attr, assigns, options = {})
      ::Liquor.render(send(attr), { assigns: assigns.merge('template' => self) }.merge(options))
    end
  end
end
