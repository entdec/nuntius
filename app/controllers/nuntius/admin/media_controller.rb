# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    # The images the email editor's Image blocks choose from and upload to
    # (TessEdit's mediaUrl): a layout's attachments, or a template's or
    # campaign's images together with its layout's. The editor refers to an
    # image by its name (see EmailImages). The Media tab deletes them here.
    #
    # A new record's editor uploads before it is saved, without an id (and
    # with the layout it starts from): the images are pending until it is
    # created, the editor referring to them by their signed ids (PendingImages).
    class MediaController < ApplicationAdminController
      OWNERS = {"layout" => "Nuntius::Layout", "template" => "Nuntius::Template", "campaign" => "Nuntius::Campaign"}.freeze
      # The editor's image references in MJML, see EmailImages
      IMAGE_REFERENCE = /{{\s*'([^']*)'\s*\|\s*(?:image_url|embed_image)\s*}}/

      before_action :set_record

      def index
        render json: {images: email_images.images.map { |attachment| image_json(attachment) }}
      end

      def create
        file = params.require(:file)
        return render(json: {errors: [t(".only_images")]}, status: :unprocessable_entity) unless file.content_type.to_s.start_with?("image/")

        name = email_images.unique_filename(file.original_filename)
        if @record.new_record?
          blob = PendingImages.upload(file, filename: name)
          return render(json: image_json(blob).merge(id: blob.signed_id), status: :created)
        end

        uploads.attach(io: file, filename: name, content_type: file.content_type)
        render json: image_json(uploads.find { |attachment| attachment.filename.to_s == name }), status: :created
      end

      # One of the record's own images, from its Media tab, which it goes back to
      def destroy
        uploads.find(params[:attachment_id]).purge_later
        redirect_to [:edit, :admin, @record], status: :see_other
      end

      # TessEdit's compile endpoint (compileUrl), with the images the MJML
      # refers to by name shown from their URLs, for the editor's preview
      def compile
        mjml = params.require(:mjml).gsub(IMAGE_REFERENCE) do |reference|
          image = email_images.find($1) || PendingImages.find($1)
          image ? email_images.url(image, **image_url_options) : reference
        end
        result = TessEdit.compile(mjml)
        render json: {html: result.html, errors: result.errors}, status: result.errors.empty? ? :ok : :unprocessable_content
      end

      private

      def set_record
        model = OWNERS.fetch(params[:owner]).constantize
        @record = if params[:id]
          model.visible.find(params[:id])
        else
          # Not saved yet, in the layout it starts from
          model.new.tap { |record| record.layout = Nuntius::Layout.visible.find_by(id: params[:layout_id]) if record.respond_to?(:layout=) }
        end
      end

      def uploads
        @record.is_a?(Nuntius::Layout) ? @record.attachments : @record.images
      end

      def email_images
        @email_images ||= EmailImages.new(@record)
      end

      # The editor keeps the id, the image's name; the URL is for its canvas
      def image_json(attachment)
        name = attachment.filename.to_s
        {id: name, url: email_images.url(attachment, **image_url_options), name: name}
      end
    end
  end
end
