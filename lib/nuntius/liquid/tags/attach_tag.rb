# frozen_string_literal: true

# Attaches files (from URL)
#
# == Basic usage:
#    {%attach 'https://www.boxture.com/assets/images/logo.png'%}
#
class AttachTag < LiquorTag
  def render(context)
    super

    return unless argv1

    message = context.registers['message']

    if argv1.is_a? String
      message.add_attachment({ url: argv1 })
    elsif argv1.instance_of?(ActiveStorageAttachedOneDrop) || argv1.instance_of?(ActiveStorage::AttachmentDrop)

      io = StringIO.new(argv1.download)
      io.rewind
      content_type = argv1.content_type
      filename = argv1.filename

      if arg(:convert) == 'pdf' && content_type != 'application/pdf'
        content_type = 'application/pdf'
        pdf = Labelary::Label.render(zpl: io.read,
                                     content_type: content_type,
                                     dpmm: 8,
                                     width: arg(:width).blank? ? 4 : arg(:width),
                                     height: arg(:height).blank? ? 6 : arg(:height))

        io = StringIO.new(pdf)
        filename = "#{filename}.pdf"
      end

      message.add_attachment({ content: io, filename: filename, content_type: content_type })
    end

    ''
  end
end

Liquid::Template.register_tag('attach', AttachTag)
