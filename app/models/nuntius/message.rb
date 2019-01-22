module Nuntius
  # Stores individual messages to individual recipients
  #
  #
  # Nuntius will have messages in states:
  #   sending - we're working on it
  #   sent - sent
  #   failed - could not send
  #   delivered - have delivery confirmation
  #   undelivered - have confirmation of non-delivery
  #   seen - when we have seen confirmation (with pixels etc)
  #   unknown - unknow status
  class Message < ApplicationRecord

    delegate :delivered?, to: :driver_message

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

    private

    # Not sure if we need these ...

    def driver_class
      Nuntius.const_get("#{driver}_driver".camelize)
    end
  end
end
