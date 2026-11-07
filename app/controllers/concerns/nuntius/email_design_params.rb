# frozen_string_literal: true

module Nuntius
  # The email editor sends its document and MJML in design_json and
  # design_mjml (app/views/nuntius/admin/shared/_email_editor.html.slim).
  module EmailDesignParams
    extend ActiveSupport::Concern

    private

    def design_params(key)
      document = params.dig(key, :design_json)
      mjml = params.dig(key, :design_mjml)
      # The editor fills in the MJML once it has compiled; without it nothing changed
      return nil if document.blank? || mjml.blank?

      # Browsers submit form fields with CRLF line endings, which MRML can't parse in mj-head
      {document: ::JSON.parse(document), mjml: mjml.gsub(/\r\n?/, "\n")}
    end

    # A template or campaign: its own part of the design, or the layout's
    # example content when it has none yet. With another layout chosen and
    # nothing from the editor, its content moves into the new layout.
    def assign_email_design(record, key)
      design = design_params(key)
      if design
        record.assign_design(**design)
      elsif record.email_design? && record.layout_id_changed?
        record.recompose
      else
        record.start_design
      end
    end
  end
end
