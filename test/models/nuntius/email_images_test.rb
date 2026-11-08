# frozen_string_literal: true

require "test_helper"

module Nuntius
  class EmailImagesTest < ActiveSupport::TestCase
    include EmailDesignHelper

    # A 1x1 transparent PNG
    PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

    setup do
      @layout = create_layout
      attach(@layout.attachments, "logo.png")
      @template = Template.create!(description: "Order", klass: "Custom", event: "order#placed", transport: "mail", to: "test@example.com", layout: @layout)
      attach(@template.images, "banner.png")
    end

    def attach(attachments, filename)
      attachments.attach(io: StringIO.new(PNG), filename: filename, content_type: "image/png")
      attachments.find { |attachment| attachment.filename.to_s == filename }
    end

    def render(source, message: nil, record: @template)
      ::Liquidum.render(source, registers: {"template" => record, "message" => message}.compact)
    end

    def blob_url_pattern(filename, host: Nuntius.config.host(nil))
      %r{\Ahttps://#{Regexp.escape(host)}/rails/active_storage/blobs/redirect/[^/]+/#{Regexp.escape(filename)}\z}
    end

    def image_node(data, src: "https://old.example.com/rails/active_storage/blobs/redirect/x/logo.png")
      {"id" => "bimage", "type" => "image", "attributes" => {"src" => src}, "data" => data, "children" => []}
    end

    test "image_url gives the URL of the template's own image" do
      assert_match blob_url_pattern("banner.png"), render("{{ 'banner.png' | image_url }}")
    end

    test "image_url gives the URL of its layout's image" do
      assert_match blob_url_pattern("logo.png"), render("{{ 'logo.png' | image_url }}")
    end

    test "image_url gives nothing for an unknown name, and a URL as it is" do
      assert_equal "", render("{{ 'missing.png' | image_url }}")
      assert_equal "https://www.example.com/a.png", render("{{ 'https://www.example.com/a.png' | image_url }}")
    end

    test "image_url takes the host for the message" do
      message = Message.new(transport: "mail", template: @template)
      hosts = []
      host = lambda do |for_message|
        hosts << for_message
        "mail.account.example.com"
      end
      Nuntius.config.stub(:host, host) do
        assert_match blob_url_pattern("logo.png", host: "mail.account.example.com"), render("{{ 'logo.png' | image_url }}", message: message)
      end
      assert_equal [message], hosts
    end

    test "image_url finds a campaign's images through the message" do
      list = nuntius_lists(:valentines)
      campaign = Campaign.create!(name: "Spring", transport: "mail", layout: @layout, list: list)
      attach(campaign.images, "spring.png")
      message = Message.new(transport: "mail", campaign: campaign)

      assert_match blob_url_pattern("spring.png"), ::Liquidum.render("{{ 'spring.png' | image_url }}", registers: {"message" => message})
    end

    test "the template's own image goes before its layout's of the same name" do
      own = attach(@template.images, "logo.png")

      assert_equal own, EmailImages.new(@template).find("logo.png")
    end

    test "of older images with the same name the first uploaded is used" do
      first = attach(@layout.attachments, "photo.png")
      first.update_column(:created_at, 1.day.ago)
      attach(@layout.attachments, "photo.png")

      assert_equal first, EmailImages.new(@layout.reload).find("photo.png")
      assert_equal 1, @layout.email_images.count { |image| image.filename.to_s == "photo.png" }
    end

    test "a new image gets a name none of the template's images or its layout's has" do
      images = EmailImages.new(@template)

      assert_equal "photo.png", images.unique_filename("photo.png")
      assert_equal "banner-2.png", images.unique_filename("banner.png")
      assert_equal "logo-2.png", images.unique_filename("logo.png")
      attach(@template.images, "logo-2.png")
      assert_equal "logo-3.png", EmailImages.new(@template.reload).unique_filename("logo.png")
      assert_equal "its-logo.png", images.unique_filename("it's-logo.png")
    end

    test "a new layout image gets a name its emails' images don't have" do
      assert_equal "banner-2.png", EmailImages.new(@layout).unique_filename("banner.png")
    end

    test "older references, a signed id or a blob URL, become the image's name" do
      logo = @layout.attachments.first
      host = "https://#{Nuntius.config.host(nil)}"
      document = {"id" => "broot", "type" => "root", "attributes" => {}, "data" => {}, "children" => [
        image_node({"image" => logo.blob.signed_id, "source" => "upload"}),
        {"id" => "bsection", "type" => "section", "attributes" => {"background-url" => "#{host}/rails/active_storage/blobs/redirect/#{logo.blob.signed_id}/logo.png"}, "data" => {"background" => "#{host}/rails/active_storage/blobs/redirect/#{logo.blob.signed_id}/logo.png"}, "children" => []}
      ]}

      normalized = EmailImages.new(@template).normalize(document, host: "editor.example.com", protocol: "https")

      image, section = normalized["children"]
      assert_equal({"image" => "logo.png", "source" => "upload"}, image["data"])
      assert_match blob_url_pattern("logo.png", host: "editor.example.com"), image.dig("attributes", "src")
      assert_equal "logo.png", section.dig("data", "background")
      assert_match blob_url_pattern("logo.png", host: "editor.example.com"), section.dig("attributes", "background-url")
      assert_equal logo.blob.signed_id, document["children"].first.dig("data", "image"), "the document itself is left as it was"
    end

    test "a reference to an image that is gone becomes a web image, keeping its URL" do
      normalized = EmailImages.new(@template).normalize([image_node({"image" => "eyJfcmFpbHMi--gone", "source" => "upload"})])

      assert_equal({"source" => "web"}, normalized.first["data"])
      assert_equal "https://old.example.com/rails/active_storage/blobs/redirect/x/logo.png", normalized.first.dig("attributes", "src")
    end

    test "web images are left as they are" do
      node = image_node({"image" => "logo.png", "source" => "web"})

      assert_equal [node], EmailImages.new(@template).normalize([node])
    end

    test "a design is stored with its uploaded images' names only" do
      @template.update!(json: [image_node({"image" => @layout.attachments.first.blob.signed_id, "source" => "upload"})])

      assert_equal [{"id" => "bimage", "type" => "image", "attributes" => {}, "data" => {"image" => "logo.png", "source" => "upload"}, "children" => []}], @template.reload.json
    end

    test "a design with a named image is sent with the image's URL" do
      @template.assign_content([], %(<mj-section><mj-column><mj-image src="{{ 'banner.png' | image_url }}" /></mj-column></mj-section>))
      @template.save!

      assert_includes @template.html, "{{ 'banner.png' | image_url }}"
      html = @template.new_messages({}).first.html
      assert_match %r{src="https://#{Regexp.escape(Nuntius.config.host(nil))}/rails/active_storage/blobs/redirect/[^/"]+/banner.png"}, html
    end

    test "an older design with an absolute image URL is sent as it was" do
      url = "https://app.example.com/rails/active_storage/blobs/redirect/eyJfcmFpbHMi--1f2e/logo.png"
      @template.assign_content([image_node({"image" => "eyJfcmFpbHMi--1f2e", "source" => "upload"}, src: url)], %(<mj-section><mj-column><mj-image src="#{url}" /></mj-column></mj-section>))
      @template.save!

      assert_includes @template.new_messages({}).first.html, %(src="#{url}")
    end
  end
end
