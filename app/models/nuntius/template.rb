module Nuntius
  class Template < ApplicationRecord
    belongs_to :layout, class_name: 'Template', optional: true

    scope :metadata, lambda { |name, value|
      where('metadata->>:name = :value', name: name, value: value)
    }
  end
end
