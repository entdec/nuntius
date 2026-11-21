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

  test "a new template's editor shows its layout's images from their URLs, before it is saved" do
    image = {"id" => "blogo", "type" => "image", "attributes" => {}, "data" => {"image" => "logo.png", "source" => "upload", "embed" => true}, "children" => []}
    @layout.update_column(:json, layout_json.merge("children" => [image, *layout_json["children"]]))

    get "/nuntius/admin/templates/new", params: {layout_id: @layout.id, transport: "mail"}

    document = JSON.parse(css_select("input[name='template[design_json]']").first["value"])
    opened = document["children"].find { |node| node["id"] == "blogo" }
    assert_match %r{/rails/active_storage/blobs/redirect/[^/]+/logo.png\z}, opened.dig("attributes", "src")
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

  test "a new campaign's editor uploads before it is saved, and the campaign keeps the images its design shows, by name" do
    get "/nuntius/admin/campaigns/new", params: {transport: "mail", layout_id: @layout.id}
    assert_select "[data-tess-edit-media-url-value='/nuntius/admin/campaigns/media?layout_id=#{@layout.id}']"
    assert_select "[data-tess-edit-compile-url-value='/nuntius/admin/campaigns/media/compile?layout_id=#{@layout.id}']"
    get "/nuntius/admin/campaigns/media", params: {layout_id: @layout.id}, as: :json
    assert_equal ["logo.png"], names, "its layout's"

    post "/nuntius/admin/campaigns/media", params: {file: upload("logo.png"), layout_id: @layout.id}
    assert_response :created
    uploaded = response.parsed_body
    assert_equal "logo-2.png", uploaded["name"], "not its layout's name"
    assert_equal ActiveStorage::Blob.find_signed(uploaded["id"]).filename.to_s, "logo-2.png", "referred to by its signed id until the campaign is saved"
    post "/nuntius/admin/campaigns/media", params: {file: upload("unused.png")}
    unused = ActiveStorage::Blob.find_signed(response.parsed_body["id"])

    content = %(<mj-section><mj-column><mj-image src="{{ '#{uploaded["id"]}' | image_url }}" /></mj-column></mj-section>)
    post "/nuntius/admin/campaigns/media/compile", params: {mjml: "<mjml><mj-body>#{content}</mj-body></mjml>", layout_id: @layout.id}, as: :json
    assert_match %r{src="https://[^"]+/logo-2.png"}, response.parsed_body["html"], "the preview shows it"

    image = {"id" => "bphoto", "type" => "image", "attributes" => {"src" => uploaded["url"]}, "data" => {"image" => uploaded["id"], "source" => "upload"}, "children" => []}
    document = Nuntius::EmailDesign.document_with(@layout.json, [image], subject: "Spring", preview_text: "")
    mjml = layout_mjml.sub(content_mjml("Example content"), "#{Nuntius::EmailDesign::CONTENT_START}\n#{content}\n#{Nuntius::EmailDesign::CONTENT_END}")
    post "/nuntius/admin/campaigns", params: {campaign: {name: "Spring", transport: "mail", layout_id: @layout.id, design_json: document.to_json, design_mjml: mjml}}

    campaign = Nuntius::Campaign.find_by!(name: "Spring")
    assert_equal ["logo-2.png"], campaign.images.map { |attachment| attachment.filename.to_s }
    assert_not campaign.images.first.blob.metadata.key?("pending")
    assert_equal "logo-2.png", campaign.json.first.dig("data", "image")
    assert_includes campaign.mjml, "{{ 'logo-2.png' | image_url }}"
    assert_not_includes campaign.html, uploaded["id"]
    assert unused.reload.metadata["pending"], "left for the host to purge"
    assert_empty unused.attachments
  end

  test "a new layout keeps the images uploaded before it was saved" do
    get "/nuntius/admin/layouts/new"
    assert_select "[data-tess-edit-media-url-value='/nuntius/admin/layouts/media']"

    post "/nuntius/admin/layouts/media", params: {file: upload("header.png")}
    uploaded = response.parsed_body
    json = layout_json
    json["children"].unshift({"id" => "bheader", "type" => "image", "attributes" => {"src" => uploaded["url"]}, "data" => {"image" => uploaded["id"], "source" => "upload"}, "children" => []})
    layout = Nuntius::Layout.create!(name: "With header", json: json, mjml: layout_mjml(header: %(<img src="{{ '#{uploaded["id"]}' | image_url }}">)))

    assert_equal ["header.png"], layout.attachments.map { |attachment| attachment.filename.to_s }
    assert_equal "header.png", layout.json["children"].first.dig("data", "image")
    assert_includes layout.mjml, "{{ 'header.png' | image_url }}"
  end

  def campaign
    @campaign ||= begin
      list = nuntius_lists(:valentines)
      list.update_column(:slug, "valentines")
      Nuntius::Campaign.create!(name: "Spring", transport: "mail", layout: @layout, list: list)
    end
  end

  test "the Media tab deletes one of the record's own images, and goes back to it" do
    banner = @template.images.attach(io: StringIO.new(PNG), filename: "banner.png", content_type: "image/png").attachments.last

    delete "/nuntius/admin/templates/#{@template.id}/media/#{banner.id}"

    assert_redirected_to "/nuntius/admin/templates/#{@template.id}/edit"
    assert_empty @template.reload.images
    # Not its layout's, which isn't the template's to delete
    delete "/nuntius/admin/templates/#{@template.id}/media/#{@layout.attachments.first.id}"
    assert_response :not_found
    assert_equal 2, @layout.reload.attachments.count
  end
end
