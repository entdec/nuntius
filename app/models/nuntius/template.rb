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

    def new_message(object, assigns = {})
      message = Nuntius::Message.new(template: self, transport: transport, nuntiable: object, metadata: metadata)

      locale_proc = Nuntius::BaseMessenger.messenger_for_obj(object).locale
      locale = instance_exec(object, &locale_proc) if locale_proc

      message.to = render(:to, assigns, locale)
      message.subject = render(:subject, assigns, locale)
      message.html = render(:html, assigns, locale, layout: layout&.data)
      message.text = render(:text, assigns, locale)

      message
    end

    def translation_scope
      scope = %w[nuntius]
      scope << layout.name.underscore.tr(' ', '_') if layout
      scope << klass.underscore.tr('/', '_')
      scope << event
      scope.join('.')
    end

    private

    def render(attr, assigns, locale, options = {})
      I18n.with_locale(locale) do
        ::Liquor.render(send(attr), { assigns: assigns, registers: { 'template' => self } }.merge(options))
      end
    end
  end
end
