# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Nuntius
  class NullSenderSmtpTest < ActiveSupport::TestCase
    test "hands an empty reverse-path to the SMTP session" do
      delivery = Nuntius::NullSenderSmtp.new(address: "smtp.example.com", port: 25, return_response: false)
      mail = Mail.new(from: "bounce@example.com", to: "user@example.com", subject: "s", body: "b")

      captured = {}
      fake_smtp = Object.new
      fake_smtp.define_singleton_method(:sendmail) do |_message, from, to|
        captured[:from] = from
        captured[:to] = to
        "250 OK"
      end

      delivery.stub(:start_smtp_session, ->(&block) { block.call(fake_smtp) }) do
        delivery.deliver!(mail)
      end

      assert_equal "", captured[:from]
      assert_includes Array(captured[:to]), "user@example.com"
    end
  end
end
