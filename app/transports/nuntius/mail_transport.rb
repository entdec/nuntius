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

      tos = message.to.split(/[\s;,]+/)

      messages = []
      message.to = tos.first
      messages << message

      tos[1..-1].each do |to|
        # FIXME: Sadly this also duplicates the attachments
        new_message = message.deep_dup
        new_message.to = to

        messages << new_message
      end

      messages.each { |m| super(m) }

      messages.first
    end
  end
end
