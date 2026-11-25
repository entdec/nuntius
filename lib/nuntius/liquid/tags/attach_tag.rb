# frozen_string_literal: true

# Attaches files to the message: from a URL, a stored file, or what a drop
# makes, one or a list of them; nothing for nothing.
#
# == Basic usage:
#    {% attach 'https://www.example.com/assets/images/logo.png' %}
#    {% attach order.label convert:'pdf' %}   a stored file (Active Storage), a ZPL label as PDF
#    {% attach contract.pdf %}                what a drop makes: {content:, filename:, content_type:}
#    {% attach invoice.documents %}           a list of those, or of stored files
#
# A URL is fetched over http(s) only: a template's text is the account's to
# write, so it can't attach a file of the server (file://).
class AttachTag < LiquidumTag
  def render(context)
    super

    message = context.registers["message"]
    return "" unless message

    attachments = argv1
    attachments = attachments.to_a if attachments.is_a?(ActiveStorageAttachedManyDrop)
    Array.wrap(attachments).each { |attachment| attach(message, attachment) }

    ""
  end

  private

  def attach(message, attachment)
    case attachment
    when String
      message.add_attachment({url: attachment}) if attachment.match?(%r{\Ahttps?://}i)
    when Hash
      made(message, attachment.to_h.symbolize_keys)
    when ActiveStorageAttachedOneDrop, ActiveStorage::AttachmentDrop
      stored(message, attachment)
    end
  end

  # What a drop makes; content a string or an IO
  def made(message, attachment)
    content = attachment[:content]
    content = StringIO.new(content) if content.is_a?(String)
    return unless content.respond_to?(:read)

    message.add_attachment({content:, filename: attachment[:filename].presence || "attachment", content_type: attachment[:content_type]})
  end

  def stored(message, attachment)
    io = StringIO.new(attachment.download)
    io.rewind
    content_type = attachment.content_type
    filename = attachment.filename

    if arg(:convert) == "pdf" && content_type != "application/pdf"
      content_type = "application/pdf"
      pdf = Labelary::Label.render(zpl: io.read,
        content_type: content_type,
        dpmm: 8,
        width: arg(:width).blank? ? 4 : arg(:width),
        height: arg(:height).blank? ? 6 : arg(:height))

      io = StringIO.new(pdf)
      filename = "#{filename}.pdf"
    end

    message.add_attachment({content: io, filename: filename, content_type: content_type})
  end
end

Liquid::Environment.default.register_tag("attach", AttachTag)
