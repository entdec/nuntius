# frozen_string_literal: true

module Nuntius
  class MailTransport < BaseTransport
    # We split per email address, to allow easy resends
    def deliver(message)

      message.html = Inky::Core.new.release_the_kraken(message.html)

      premailer = Premailer.new(message.html, with_html_string: true)
      message.html = premailer.to_inline_css
      message.text = premailer.to_plain_text

      message.request_id = SecureRandom.uuid
      message.to.split(',').each do |to|
        new_message = message.dup
        new_message.to = to
        super(new_message)
      end
    end
  end
end
