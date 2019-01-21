# frozen_string_literal: true

#
# - Look for messages for the current channel
# - See if there are retailer specific messages, if so, only look for that retailer
# - Find messages for the current klass/event
#
module Nuntius
  class MessageJob < ApplicationJob
    queue_as :message

    def perform(obj, event, opts = {})
      return unless obj

      klass = obj.class.name

      Nuntius.logger.info "MessageJob performing for #{klass} #{event}"

      scope = Message.all
      scope = Nuntius.config.base_scope(scope, obj)

      scope = scope.where(klass: klass)
      scope = scope.where(event: event)

      Rails.logger.info "MessageJob found no messages for #{klass} #{event}" unless scope.any?

      scope.each do |message|
        message.process(obj, opts)
      end
    end
  end
end
