# frozen_string_literal: true

module Nuntius
  module Nuntiable
    extend ActiveSupport::Concern

    class_methods do
      def nuntiable_options
        @_nuntius_nuntiable_options || {}
      end

      def messenger
        Nuntius::BaseMessenger.messenger_for_class(name)
      end
    end

    included do
      raise "Nuntius Messenger has not been implemented for class #{name}" unless messenger

      Nuntius.config.add_nuntiable_class(self)
      has_many :messages, as: :nuntiable, class_name: 'Nuntius::Message'
    end
  end
end
