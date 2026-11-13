# frozen_string_literal: true

module Nuntius
  module Concerns
    # A template or campaign designed in the email editor: its own blocks go
    # into the Content block of its layout, which it follows when the layout
    # changes. Its other transports' messages are edited in an editor too
    # (message_design?), with their settings in its root, by the class's
    # DESIGN_ATTRIBUTES.
    #
    #   json          its own blocks (the Content block's children)
    #   mjml          the whole email, layout included
    #   html          that compiled, with Liquid left for sending
    #   subject, preview_text
    module EmailDesigned
      extend ActiveSupport::Concern

      # In the editor only the Content block, the subject and the preview text
      # are its own, and a template's settings in its root (DESIGN_ATTRIBUTES);
      # the rest belongs to the layout.
      EDITOR_LOCK = {except: ["content"], fields: ["data.subject", "data.preheader", "data.from", "data.to", "data.linkTracking", "data.openTracking"]}.freeze

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
        transport.to_s == "mail"
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

        EmailDesign.document_with(layout.json, json, subject: subject, preview_text: preview_text, data: design_data)
      end

      # Takes the document and MJML the editor submits. Only the Content
      # block's insides, the subject and the preview text are taken; the rest
      # comes from the layout as it is now.
      def assign_design(document:, mjml:)
        document = ::JSON.parse(document) if document.is_a?(String)
        self.json = EmailDesign.content_nodes(document) || []
        self.subject = document.dig("data", "subject")
        self.preview_text = document.dig("data", "preheader")
        assign_design_data(document["data"] || {})
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

      # Whether it is edited in the editor for its transport's messages: SMS,
      # Push, Teams, Slack and Voice (app/javascript/nuntius/kits/messages.js)
      def message_design?
        !email? && self.class::DESIGN_ATTRIBUTES.key?(transport.to_s)
      end

      # The document that editor opens: a root of its transport, with its settings
      def message_document
        {"id" => "broot", "type" => transport.to_s, "attributes" => {}, "data" => design_data, "children" => []}
      end

      # Takes its settings from the document that editor submits
      def assign_message_design(document)
        document = ::JSON.parse(document) if document.is_a?(String)
        assign_design_data(document["data"] || {})
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

      # Its attributes edited in the editor's root, by their keys in its data
      # (see app/javascript/nuntius/blocks/email.js)
      def design_attributes
        {}
      end

      def design_data
        design_attributes.to_h { |key, attribute| [key, public_send(attribute)] }
      end

      # The ones the data has
      def assign_design_data(data)
        design_attributes.each { |key, attribute| public_send(:"#{attribute}=", data[key]) if data.key?(key) }
      end

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
