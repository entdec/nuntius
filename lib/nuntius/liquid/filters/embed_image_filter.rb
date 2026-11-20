# frozen_string_literal: true

module EmbedImageFilter
  # Attaches an image to the email and returns a cid: reference to it, so
  # the email shows it without loading it from the web.
  #
  # Example:
  #   <img src="{{ 'logo.png' | embed_image }}">  (an image uploaded in the editor, by
  #                                                 its name, as its Image block puts it)
  #   <img src="{{ 'https://www.example.com/logo.png' | embed_image }}">
  #   <img src="{{ template.layout.attachments.first | embed_image }}">
  #   <img src="{{ 'eyJfcmFpbHMi…--1f2e3d' | embed_image }}">  (a stored image's signed id,
  #                                                     as older Image blocks put it)
  #
  # Each image is attached once per message, however often it is used.
  # Without a message (a preview) it is linked instead: a URL as it is, a
  # stored image from its URL on Nuntius' host.
  def embed_image(input)
    message = @context.registers["message"]
    input = stored_image(input) || input
    return preview_url(input) unless message

    data = input.is_a?(String) ? nil : input.download
    key = data ? Digest::SHA256.hexdigest(data) : input
    embedded = (@context.registers["embedded_images"] ||= {})
    embedded[key] ||= begin
      options = data ? {content: StringIO.new(data), filename: input.filename.to_s, content_type: input.content_type} : {url: input}
      attachment = message.add_attachment(options.merge(inline: true))
      attachment ? "cid:#{attachment.content_id}" : input.to_s
    end
  end

  private

  def preview_url(input)
    return input if input.is_a?(String)

    input.respond_to?(:signed_id) ? Nuntius::EmailImages.new(nil).url(input) : ""
  end

  # The editor's image a name refers to (see Nuntius::EmailImages), or the
  # Active Storage blob a signed id (not a URL) refers to
  def stored_image(input)
    return unless input.is_a?(String) && !input.match?(Nuntius::EmailImages::URL)

    Nuntius::EmailImages.in_context(@context).find(input) || ActiveStorage::Blob.find_signed(input)
  end
end

Liquid::Environment.default.register_filter(EmbedImageFilter)
