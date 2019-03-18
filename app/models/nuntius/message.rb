module Nuntius
  # Stores individual messages to individual recipients
  #
  #
  # Nuntius will have messages in states:
  #   sending - we're working on it
  #   delivered - have delivery confirmation
  #   undelivered - have confirmation of non-delivery
  # Not all transports may provide all states
  class Message < ApplicationRecord
    belongs_to :template, optional: true
    belongs_to :parent_message, class_name: 'Message', optional: true
    belongs_to :nuntiable, polymorphic: true, optional: true

    validates :transport, presence: true

    def draft?
      status == 'draft'
    end

    def sending?
      status == 'sending'
    end

    def delivered?
      status == 'delivered'
    end

    def undelivered?
      status == 'undelivered'
    end

    # Removes only draft child messages
    def cleanup!
      Nuntius::Message.where(status: 'draft').where(parent_message: self).delete_all
    end

    def nuntius_provider(message)
      klass = Nuntius::BaseProvider.class_from_name(provider, transport)
      klass ||= Nuntius::BaseProvider
      klass.new
    end
  end
end
