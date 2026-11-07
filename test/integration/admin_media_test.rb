# frozen_string_literal: true

require "test_helper"

class AdminMediaTest < ActionDispatch::IntegrationTest
  include EmailDesignHelper

  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

  setup do
    @layout = create_layout
    @layout.attachments.attach(io: StringIO.new(PNG), filename: "logo.png", content_type: "image/png")
    @layout.attachments.attach(io: StringIO.new("Terms"), filename: "terms.txt", content_type: "text/plain")
    @template = Nuntius::Template.create!(description: "Order", klass: "Custom", event: "order#placed", transport: "mail", layout: @layout)
  end

  def upload(name = "photo.png", type = "image/png", content = PNG)
    Rack::Test::UploadedFile.new(StringIO.new(content), type, original_filename: name)
  end

  def names
    response.parsed_body["images"].map { |image| image["name"] }
  end

  test "a layout's images are its image attachments" do
    get "/nuntius/admin/layouts/#{@layout.id}/media", as: :json

    assert_response :success
    assert_equal ["logo.png"], names
  end

  test "a template chooses from its own images and its layout's" do
    @template.images.attach(io: StringIO.new(PNG), filename: "banner.png", content_type: "image/png")

    get "/nuntius/admin/templates/#{@template.id}/media", as: :json

    assert_equal ["banner.png", "logo.png"], names
    image = response.parsed_body["images"].first
    # The editor keeps the name, the URL is for its canvas
    assert_equal "banner.png", image["id"]
    # On Nuntius' public host, whatever port the admin runs on
    assert_match %r{\Ahttps://#{Regexp.escape(Nuntius.config.host(nil))}/rails/active_storage/blobs/.+/banner.png\z}, image["url"]
  end

  test "image URLs don't take the admin's port" do
    get "http://admin.example.com:3000/nuntius/admin/layouts/#{@layout.id}/media", as: :json

    assert_no_match(/:3000/, response.parsed_body["images"].first["url"])
  end

  test "uploading adds an image to the template" do
    post "/nuntius/admin/templates/#{@template.id}/media", params: {file: upload}

    assert_response :created
    assert_equal ["photo.png"], @template.reload.images.map { |image| image.filename.to_s }
    assert_equal "photo.png", response.parsed_body["name"]
  end

  test "an upload gets a name the template's images and its layout's don't have yet" do
    post "/nuntius/admin/templates/#{@template.id}/media", params: {file: upload}
    post "/nuntius/admin/templates/#{@template.id}/media", params: {file: upload}
    post "/nuntius/admin/templates/#{@template.id}/media", params: {file: upload("logo.png")}

    assert_equal ["photo.png", "photo-2.png", "logo-2.png"], @template.reload.images.sort_by(&:created_at).map { |image| image.filename.to_s }
    assert_equal "logo-2.png", response.parsed_body["id"]
    assert_equal "logo-2.png", response.parsed_body["name"]
    assert_match %r{/logo-2.png\z}, response.parsed_body["url"]
  end

  test "the preview shows the images the design refers to by name" do
    @template.images.attach(io: StringIO.new(PNG), filename: "banner.png", content_type: "image/png")
    mjml = %(<mjml><mj-body><mj-section><mj-column><mj-image src="{{ 'banner.png' | image_url }}" /><mj-image src="{{ 'logo.png' | embed_image }}" /><mj-image src="{{ 'gone.png' | image_url }}" /></mj-column></mj-section></mj-body></mjml>)

    post "/nuntius/admin/templates/#{@template.id}/media/compile", params: {mjml: mjml}, as: :json

    assert_response :success
    html = response.parsed_body["html"]
    assert_match %r{src="https://[^"]+/rails/active_storage/blobs/redirect/[^"]+/banner.png"}, html
    assert_match %r{src="https://[^"]+/rails/active_storage/blobs/redirect/[^"]+/logo.png"}, html
    assert_includes html, "{{ 'gone.png' | image_url }}"
  end

  test "the editor opens with older image references as names, shown from their URLs, and previews through the media" do
    signed_id = @layout.attachments.first.blob.signed_id
    image = {"id" => "bimage", "type" => "image", "attributes" => {"src" => "https://old.example.com/rails/active_storage/blobs/redirect/#{signed_id}/logo.png"}, "data" => {"image" => signed_id, "source" => "upload"}, "children" => []}
    @template.update_column(:json, [image])

    get "/nuntius/admin/templates/#{@template.id}/edit"

    document = JSON.parse(css_select("input[name='template[design_json]']").first["value"])
    opened = Nuntius::EmailDesign.content_nodes(document).first
    assert_equal "logo.png", opened.dig("data", "image")
    assert_match %r{\Ahttps://#{Regexp.escape(Nuntius.config.host(nil))}/rails/active_storage/blobs/redirect/[^/]+/logo.png\z}, opened.dig("attributes", "src")
    assert_select "[data-tess-edit-compile-url-value='/nuntius/admin/templates/#{@template.id}/media/compile']"
  end

  test "uploading to a layout adds it to its attachments" do
    post "/nuntius/admin/layouts/#{@layout.id}/media", params: {file: upload}

    assert_includes @layout.reload.attachments.map { |attachment| attachment.filename.to_s }, "photo.png"
  end

  test "only images can be uploaded" do
    post "/nuntius/admin/campaigns/#{campaign.id}/media", params: {file: upload("notes.txt", "text/plain", "hi")}

    assert_response :unprocessable_entity
    assert_equal ["Only images can be uploaded"], response.parsed_body["errors"]
    assert_empty campaign.reload.images
  end

  test "the editors know where their images are" do
    get "/nuntius/admin/templates/#{@template.id}/edit"
    assert_select "[data-tess-edit-media-url-value='/nuntius/admin/templates/#{@template.id}/media']"

    get "/nuntius/admin/layouts/#{@layout.id}/edit"
    assert_select "[data-tess-edit-media-url-value='/nuntius/admin/layouts/#{@layout.id}/media']"

    get "/nuntius/admin/campaigns/#{campaign.id}/edit"
    assert_select "[data-tess-edit-media-url-value='/nuntius/admin/campaigns/#{campaign.id}/media']"
  end

  test "a new layout has no images to choose from until it is saved" do
    get "/nuntius/admin/layouts/new"

    assert_select "[data-controller='tess-edit']:not([data-tess-edit-media-url-value])"
  end

  def campaign
    @campaign ||= begin
      list = nuntius_lists(:valentines)
      list.update_column(:slug, "valentines")
      Nuntius::Campaign.create!(name: "Spring", transport: "mail", layout: @layout, list: list)
    end
  end
end
