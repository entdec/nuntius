# frozen_string_literal: true

require "test_helper"

module Nuntius
  class MessageImagesTest < ActionDispatch::IntegrationTest
    test "the message in the browser shows its embedded images from storage" do
      message = Message.new(transport: "mail", to: "user@example.com", subject: "Test")
      image = message.add_attachment(content: StringIO.new("png"), filename: "logo.png", content_type: "image/png", inline: true)
      message.html = %(<img src="cid:#{image.content_id}">)
      message.save!

      get "/nuntius/messages/#{message.id}"

      assert_response :success
      assert_select "img[src^='/rails/active_storage/blobs/']"
      assert_select "a", text: "logo.png", count: 0
    end
  end
end
