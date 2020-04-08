# frozen_string_literal: true

module Nuntius
  class Template < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped

    belongs_to :layout, optional: true
    has_many :messages, class_name: 'Nuntius::Message', dependent: :nullify

    LIQUID_TAGS = /{%(?:(?!%}).)*%}|{{(?:(?!}}).)*}}/.freeze

    validates :description, presence: true
    validates :from, liquid: true
    validates :to, liquid: true
    validates :subject, liquid: true
    validates :html, liquid: true
    validates :text, liquid: true

    validates :event, presence: true
    validates :event, format: { with: /.+#.+/ }, if: ->(t) { t.klass == 'Custom' }
    validates :interval, format: { with: /\A[1-9][0-9]*\s(day|hour|minute)s?\z/ }

    def new_message(object, assigns = {}, params = {})
      message = Nuntius::Message.new(template: self, transport: transport, metadata: metadata)
      message.nuntiable = object unless object.is_a? Hash

      locale_proc = Nuntius::BaseMessenger.messenger_for_obj(object).locale
      locale = instance_exec(object, &locale_proc) if locale_proc
      locale = params[:locale].to_sym if params[:locale]

      message.to = render(:to, assigns, locale).split(',').reject(&:empty?).join(',')
      message.subject = render(:subject, assigns, locale)
      message.html = render(:html, assigns, locale, layout: layout&.data)
      message.text = render(:text, assigns, locale)
      message.payload = render(:payload, assigns, locale)

      message
    end

    def translation_scope
      scope = %w[]
      scope << layout.name.underscore.tr(' ', '_') if layout
      scope << klass.underscore.tr('/', '_')
      scope << event
      scope << transport
      scope << description.underscore.gsub(/[^a-z]+/, '_') if description
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
        if attr == :payload
          YAML.safe_load(::Liquor.render(send(attr), { assigns: assigns.merge('template' => self), registers: { 'template' => self } }.merge(options)))
        elsif attr == :html
          ::Liquor.render(send(attr), { filter: 'markdown', assigns: assigns.merge('template' => self), registers: { 'template' => self } }.merge(options))
        else
          ::Liquor.render(send(attr), { assigns: assigns.merge('template' => self), registers: { 'template' => self } }.merge(options))
        end
      end
    end
  end
end
