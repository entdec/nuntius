# frozen_string_literal: true

module Nuntius
  module Concerns
    # A template or campaign designed in the email editor: its own blocks go
    # into the Content block of its layout, which it follows when the layout
    # changes.
    #
    #   json          its own blocks (the Content block's children)
    #   mjml          the whole email, layout included
    #   html          that compiled, with Liquid left for sending
    #   subject, preview_text
    module EmailDesigned
      extend ActiveSupport::Concern

      EMAIL_TRANSPORTS = %w[mail lmtp].freeze
      # In the editor only the Content block, the subject and the preview text
      # are its own; the rest belongs to the layout.
      EDITOR_LOCK = {except: ["content"], fields: ["data.subject", "data.preheader"]}.freeze

      included do
        # Images for the editor's Image blocks, besides the layout's own (attachments)
        has_many_attached :images, service: Nuntius.config.active_storage_service

        validate :design_compiles
        before_save :store_image_names, if: :json_changed?
        # Every email needs a layout when edited in the admin; the old ones keep
        # their old layout until they are converted.
        validates :layout, presence: true, on: :admin, if: -> { email? && old_layout.nil? }
      end

      def email?
        EMAIL_TRANSPORTS.include?(transport)
      end

      # The images its editor can choose from: its own and its layout's, one
      # per name (its own first, then the first uploaded, see EmailImages)
      def email_images
        own = images.sort_by { |image| [image.created_at, image.id] }
        (own + Array(layout&.email_images)).uniq { |image| image.filename.to_s }
      end

      # The metadata variables its design still uses, see MetadataVariables
      def metadata_variables
        return [] unless email_design?

        MetadataVariables.in(self, subject, preview_text, mjml, text)
      end

      # Whether it is designed in the email editor, rather than an older
      # template or campaign with an old layout or plain HTML.
      def email_design?
        mjml.present?
      end

      # The document the editor opens: the layout's, with this one's blocks,
      # subject and preview text in it.
      def editor_document
        return nil unless layout

        EmailDesign.document_with(layout.json, json, subject: subject, preview_text: preview_text)
      end

      # Takes the document and MJML the editor submits. Only the Content
      # block's insides, the subject and the preview text are taken; the rest
      # comes from the layout as it is now.
      def assign_design(document:, mjml:)
        document = ::JSON.parse(document) if document.is_a?(String)
        self.json = EmailDesign.content_nodes(document) || []
        self.subject = document.dig("data", "subject")
        self.preview_text = document.dig("data", "preheader")
        compose(EmailDesign.content_of(mjml))
      rescue ::JSON::ParserError, EmailDesign::Error => e
        @design_error = e.message
      end

      # A new email in a layout starts with the layout's example content.
      def start_design
        return if !layout || email_design? || old_layout

        self.json = EmailDesign.content_nodes(layout.json) || []
        compose(EmailDesign.content_of(layout.mjml))
      rescue EmailDesign::Error => e
        @design_error = e.message
      end

      # Its own blocks, and their MJML, put into its layout
      def assign_content(nodes, content_mjml)
        self.json = nodes
        compose(content_mjml)
      rescue EmailDesign::Error => e
        @design_error = e.message
      end

      # Puts its content into the layout's current MJML again and compiles it.
      def recompose
        compose(EmailDesign.content_of(mjml))
      rescue EmailDesign::Error => e
        @design_error = e.message
      end

      private

      def compose(content)
        @design_error = nil
        raise EmailDesign::Error, "Choose a layout" unless layout

        self.mjml = EmailDesign.merge(layout.mjml, content, subject: subject, preview_text: preview_text)
        result = TessEdit.compile(mjml)
        raise EmailDesign::Error, result.errors.join("; ") unless result.html

        self.html = result.html
      end

      # Uploaded images are kept by name only, see EmailImages
      def store_image_names
        self.json = EmailImages.new(self).normalize(json)
      end

      def design_compiles
        errors.add(:base, "The email could not be put together: #{@design_error}") if @design_error
      end
    end
  end
end
