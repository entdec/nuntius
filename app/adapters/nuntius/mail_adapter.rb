# frozen_string_literal: true

module Nuntius
  class MailAdapter < BaseAdapter

    def send(message)
      # Try each driver in turn until message is delivered
      # Use timeout, break if delivered

      # drivers.each do |driver|
      #   driver.send(from, to, text, html)
      #
      #   break if delivered?
      #
      # end
    end
  end
end
