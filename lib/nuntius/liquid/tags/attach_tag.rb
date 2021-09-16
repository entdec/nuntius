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

    binding.pry

    if argv1.is_a? String
      message.add_attachment({ url: argv1 })
    elsif argv1.instance_of?(ActiveStorageAttachedOneDrop)
      message.add_attachment({ content: StringIO.new(argv1.download), filename: argv1.filename, content_type: argv1.content_type })
    elsif argv1.instance_of?(ActiveStorage::AttachmentDrop)
      message.add_attachment({ content: StringIO.new(argv1.download), filename: argv1.filename, content_type: argv1.content_type })
    end

    nil
  end
end

Liquid::Template.register_tag('attach', AttachTag)
