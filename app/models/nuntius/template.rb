module Nuntius
  class Template < ApplicationRecord
    belongs_to :layout, class_name: 'Template', optional: true

    scope :metadata, lambda { |name, value|
      where('metadata->>:name = :value', name: name, value: value)
    }

    def new_message(assigns)
      message = Nuntius::Message.new(template: self, transport: transport)

      message.to = render(:to, assigns)
      message.subject = render(:subject, assigns)
      message.html = render(:html, assigns, layout: layout&.html)
      message.text = render(:text, assigns, layout: layout&.text)

      message
    end

    private

    def render(attr, assigns, options = {})
      ::Liquor.render(send(attr),
                    assigns: assigns.merge('template' => self).merge(options))
    end
  end
end
