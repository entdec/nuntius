# frozen_string_literal: true

class MessageInstance < ApplicationRecord
  belongs_to :message
  belongs_to :messagable, polymorphic: true

  def resend!
    event = message.event == '*' ? 'anything' : message.event.split(',').first.strip
    MessageJob.perform_now(messagable, event)
  end
end
