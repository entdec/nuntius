# frozen_string_literal: true

module Nuntius
  module Concerns
    module Yamlify
      extend ActiveSupport::Concern

      class_methods do
        def yamlify(attr)
          # YAML that can't be read is an error on the attribute, keeping its value
          define_method(:"#{attr}_yaml=") do |yaml|
            @yaml_errors&.delete(attr)
            write_attribute attr, YAML.safe_load(yaml.gsub("\t", "  "))
          rescue Psych::Exception => error
            (@yaml_errors ||= {})[attr] = error.message
          end

          validate do
            (@yaml_errors || {}).each { |name, message| errors.add(name, :invalid_yaml, problem: message) }
          end

          define_method(:"#{attr}_yaml") do
            return "" if attributes[attr.to_s].blank?

            YAML.dump(attributes[attr.to_s])
          end
        end
      end
    end
  end
end
