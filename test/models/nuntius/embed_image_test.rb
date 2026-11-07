# frozen_string_literal: true

require "test_helper"

module Nuntius
  class EmbedImageTest < ActiveSupport::TestCase
    include EmailDesignHelper

    # A 1x1 transparent PNG
    PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

    setup do
      Mail::TestMailer.deliveries.clear
    end

    def render(source, message:, assigns: {})
      ::Liquidum.render(source, assigns: assigns, registers: {"message" => message})
    end

    def logo_layout
      layout = create_layout
      layout.attachments.attach(io: StringIO.new(PNG), filename: "logo.png", content_type: "image/png")
      layout
    end

    def build_message
      Message.new(transport: "mail", provider: "smtp", to: "user@example.com", subject: "Test", text: "Body")
    end

    test "attaches a stored image inline and refers to it by cid" do
      message = build_message
      html = render(%(<img src="{{ layout.attachments.first | embed_image }}">), message: message, assigns: {"layout" => logo_layout})

      image = message.attachments.sole
      assert image.inline
      assert_equal %(<img src="cid:#{image.content_id}">), html
      assert_equal "logo.png", image.filename.to_s
    end

    test "attaches an image from a URL" do
      file = Tempfile.new(["logo", ".png"]).tap { |f| f.binmode.write(PNG) && f.flush }
      message = build_message

      html = render(%({{ "file://#{file.path}" | embed_image }}), message: message)

      assert_equal "cid:#{message.attachments.sole.content_id}", html
    end

    test "attaches an image once, however often it is used" do
      message = build_message
      html = render(%({{ layout.attachments.first | embed_image }} {{ layout.attachments.first | embed_image }}), message: message, assigns: {"layout" => logo_layout})

      assert_equal 1, message.attachments.size
      assert_equal 2, html.scan("cid:#{message.attachments.first.content_id}").size
    end

    test "attaches a stored image by its signed id, as the editor's Image block refers to it" do
      blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(PNG), filename: "banner.png", content_type: "image/png")
      message = build_message

      html = render(%(<img src="{{ '#{blob.signed_id}' | embed_image }}">), message: message)

      image = message.attachments.sole
      assert_equal %(<img src="cid:#{image.content_id}">), html
      assert_equal "banner.png", image.filename.to_s
      assert_equal "image/png", image.content_type
    end

    test "attaches an image uploaded in the editor by its name" do
      layout = logo_layout
      template = Template.create!(description: "Order", klass: "Custom", event: "order#placed", transport: "mail", layout: layout)
      message = build_message

      html = ::Liquidum.render(%(<img src="{{ 'logo.png' | embed_image }}">), registers: {"template" => template, "message" => message})

      image = message.attachments.sole
      assert_equal %(<img src="cid:#{image.content_id}">), html
      assert_equal "logo.png", image.filename.to_s
    end

    test "leaves a URL as it is without a message" do
      assert_equal "https://example.com/logo.png", ::Liquidum.render(%({{ "https://example.com/logo.png" | embed_image }}))
    end

    test "the mail has the HTML and its images together, apart from other attachments" do
      message = build_message
      message.html = render(%(<p>Hi</p><img src="{{ layout.attachments.first | embed_image }}">), message: message, assigns: {"layout" => logo_layout})
      message.add_attachment(content: StringIO.new("%PDF"), filename: "invoice.pdf", content_type: "application/pdf")
      message.save!

      SmtpMailProvider.new(message).deliver

      mail = Mail::TestMailer.deliveries.last
      alternative = mail.parts.find { |part| part.mime_type == "multipart/alternative" }
      related = alternative.parts.find { |part| part.mime_type == "multipart/related" }
      assert_equal "text/html", related.parts.first.mime_type
      image = related.parts.last
      assert_equal "<#{message.attachments.find(&:inline).content_id}>", image.content_id
      assert_equal PNG, image.decoded
      assert_equal "base64", image.content_transfer_encoding
      assert_equal ["invoice.pdf"], mail.parts.select(&:attachment?).map(&:filename)
    end
  end
end
