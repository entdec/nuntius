# frozen_string_literal: true

module Nuntius
  module Concerns
    module MetadataScoped
      extend ActiveSupport::Concern

      included do
        scope :visible, -> { instance_exec(&Nuntius.config.visible_scope) }
        before_save :add_metadata
      end

      private

      def add_metadata
        self.metadata ||= {}
        unless Nuntius.config.metadata_fields.empty?
          Nuntius.config.metadata_fields.each do |field, data|
            if data[:current]
              current = data[:current]
              metadata[field] ||= instance_exec(&current)
            end
          end
        end
        instance_exec(&Nuntius.config.add_metadata)      end
    end
  end
end
