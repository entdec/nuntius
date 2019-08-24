# frozen_string_literal: true

module Nuntius
  class MailTransport < BaseTransport
    # We split per email address, to allow easy resends
    def deliver(message)

      # Possibly we could create message.text using: Nokogiri::HTML(t.html.gsub('<br>',"\r\n")).text
      if message.html.present?
        message.html = Inky::Core.new.release_the_kraken(message.html)
        message.html = Premailer.new(message.html, with_html_string: true).to_inline_css
      end

      message.request_id = SecureRandom.uuid
      message.to.split(',').each do |to|
        new_message = message.dup
        new_message.to = to
        super(new_message)
      end
    end
  end
end
