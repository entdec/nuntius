module Nuntius
  class Template < ApplicationRecord
    belongs_to :layout, class_name: 'Template', optional: true

    scope :metadata, lambda { |name, value|
      where('metadata->>:name = :value', name: name, value: value)
    }

    def new_message
      Nuntius::Message.new(template: template, transport: transport)
    end
  end
end
