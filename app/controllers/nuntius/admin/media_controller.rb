# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    # The images the email editor's Image blocks choose from and upload to
    # (TessEdit's mediaUrl): a layout's attachments, or a template's or
    # campaign's images together with its layout's.
    class MediaController < ApplicationAdminController
      OWNERS = {"layout" => "Nuntius::Layout", "template" => "Nuntius::Template", "campaign" => "Nuntius::Campaign"}.freeze

      before_action :set_record

      def index
        render json: {images: images.map { |attachment| image_json(attachment.blob) }}
      end

      def create
        file = params.require(:file)
        return render(json: {errors: [t(".only_images")]}, status: :unprocessable_entity) unless file.content_type.to_s.start_with?("image/")

        uploads.attach(file)
        render json: image_json(uploads.last.blob), status: :created
      end

      private

      def set_record
        @record = OWNERS.fetch(params[:owner]).constantize.visible.find(params[:id])
      end

      def uploads
        @record.is_a?(Nuntius::Layout) ? @record.attachments : @record.images
      end

      def images
        @record.email_images
      end

      # The id is what embed_image takes to send the image with the email
      def image_json(blob)
        {id: blob.signed_id, url: main_app.rails_blob_url(blob, **url_options_for_email), name: blob.filename.to_s}
      end

      # Emails load images from Nuntius' public host, not the admin's, so
      # nothing (like the port) comes from the admin's request
      def url_options_for_email
        host = Nuntius.config.host(nil).presence
        return {host: request.host_with_port, protocol: request.protocol} unless host

        host.include?("://") ? {host: host, port: nil} : {host: host, protocol: "https", port: nil}
      end
    end
  end
end
