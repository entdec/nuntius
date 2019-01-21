# frozen_string_literal: true

class TimestampBasedMessagesRunner < ApplicationRunner
  def perform
    Message.timestamp_based.each do |message|
      rescued("Message #{message.id}: #{message.description}") do
        TimestampBasedMessageSendService.new(message).call
      end
    end
  end
end
