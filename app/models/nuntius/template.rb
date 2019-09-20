# frozen_string_literal: true

module Nuntius
  class Template < ApplicationRecord
    include Concerns::MetadataScoped

    belongs_to :layout, optional: true
    has_many :messages, class_name: 'Nuntius::Message'

    LIQUID_TAGS = /{%(?:(?!%}).)*%}|{{(?:(?!}}).)*}}/.freeze

    # TODO: attachments - also templates could have attachments

    validates :description, presence: true

    scope :metadata_blank, lambda { |name|
      where('metadata->>:name IS NULL', name: name)
    }

    scope :metadata_eql, lambda { |name, value|
      where('metadata->>:name = :value', name: name, value: value)
    }

    scope :metadata_blank_or_eql, lambda { |name, value|
      where('metadata->>:name IS NULL OR metadata->>:name = :value', name: name, value: value)
    }

    scope :metadata_in, lambda { |name, value|
      where('metadata->>:name IN (:value)', name: name, value: value)
    }

    scope :metadata_blank_or_in, lambda { |name, value|
      where('metadata->>:name IS NULL OR metadata->>:name IN (:value)', name: name, value: value)
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

    # Trix correctly escapes the HTML, but for liquid this is not what we need.
    # This replaces html-entities within the liquid tags ({%...%} and {{...}})
    def html=(html)
      html_unescaped_liquid = html.gsub(LIQUID_TAGS) do |m|
        CGI.unescape_html(m)
      end
      write_attribute :html, html_unescaped_liquid if html
    end

    private

    def render(attr, assigns, locale, options = {})
      I18n.with_locale(locale) do
        ::Liquor.render(send(attr), { assigns: assigns.merge('template' => self), registers: { 'template' => self } }.merge(options))
      end
    end
  end
end
