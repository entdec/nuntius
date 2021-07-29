# frozen_string_literal: true

module Nuntius
  module Concerns
    module Yamlify
      extend ActiveSupport::Concern

      class_methods do
        def yamlify(attr)
          define_method(:"#{attr}_yaml=") do |yaml|
            write_attribute attr, YAML.safe_load(yaml.gsub("\t", '  '))
          end

          define_method(:"#{attr}_yaml") do
            return '' if attributes[attr.to_s].blank?

            YAML.dump(attributes[attr.to_s])
          end
        end
      end
    end
  end
end
