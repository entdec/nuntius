# frozen_string_literal: true

class MessageInstance < ApplicationRecord
  belongs_to :message
  belongs_to :messagable, polymorphic: true, optional: true

  def resend!
    case message.kind
    when 'email'
      message.send_mail(messagable, {})
    when 'sms'
      message.send_sms(messagable, {})
    when 'push'
      message.send_push(messagable, {})
    end
  end
end
