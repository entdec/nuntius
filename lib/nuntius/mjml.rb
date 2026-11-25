# frozen_string_literal: true

require "mrml"

module Nuntius
  # MJML → HTML with MRML (the mrml gem, precompiled, no Node or Rust needed).
  # Liquid passes through untouched. The email editor (app/javascript/nuntius/email)
  # compiles through TessEdit's endpoint with this, as TessEdit's "mjml"
  # compiler, so its canvas shows the HTML Nuntius sends.
  module Mjml
    module_function

    # A TessEdit::Result: html, nil when the MJML can't be parsed, and errors,
    # the reasons. Browsers submit form fields with CRLF line endings, which
    # MRML can't parse in mj-head, so line endings become LF first.
    def compile(mjml)
      TessEdit::Result.new(html: MRML::Template.new(mjml.to_s.gsub(/\r\n?/, "\n")).to_html, errors: [])
    rescue MRML::Error => error
      TessEdit::Result.new(html: nil, errors: [error.message])
    end
  end
end
