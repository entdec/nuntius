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
      html = MRML::Template.new(mjml.to_s.gsub(/\r\n?/, "\n")).to_html
      TessEdit::Result.new(html: full_width_backgrounds(html), errors: [])
    rescue MRML::Error => error
      TessEdit::Result.new(html: nil, errors: [error.message])
    end

    # A full-width section's or wrapper's background image. MRML (1.10) puts
    # it on the section's table only, as MJML does. Premailer (MailTransport)
    # moves a table's CSS background image into its background attribute,
    # which Apple Mail doesn't show: it goes on a div around the table
    # instead, as a section that isn't full width has it.
    #
    # Outlook's VML for it is meant to be in conditional comments, which MRML
    # leaves out of balance: the <v:rect> opens before the comment does, and
    # the comment closing it isn't closed, commenting out the rest of the email
    # up to the next comment's end. They're put back as MJML has them.
    FULL_WIDTH_TABLE = %r{<table border="0" cellpadding="0" cellspacing="0" role="presentation" align="center" background="[^"]*" style="([^"]*)"><tbody><tr><td>(?:<!--\[if mso \| IE\]>)?(<v:rect mso-width-percent="1000")}
    FULL_WIDTH_END = %r{<!--\[if mso \| IE\]></v:textbox></v:rect>(?:<!\[endif\]-->)?</td></tr></tbody></table>}

    def full_width_backgrounds(html)
      html.gsub(FULL_WIDTH_TABLE) {
        style, rect = $1, $2
        %(<div style="#{style.sub("width:100%;", "")}"><table border="0" cellpadding="0" cellspacing="0" role="presentation" align="center" style="width:100%;"><tbody><tr><td><!--[if mso | IE]>#{rect})
      }.gsub(FULL_WIDTH_END, "<!--[if mso | IE]></v:textbox></v:rect><![endif]--></td></tr></tbody></table></div>")
    end
  end
end
