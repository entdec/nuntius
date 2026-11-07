# frozen_string_literal: true

module ImageUrlFilter
  # The URL of an image uploaded in the email editor, by its name: one of
  # the template's or campaign's own images, or else its layout's (see
  # Nuntius::EmailImages), on Nuntius' host for the message.
  #
  # Example:
  #   <img src="{{ 'logo.png' | image_url }}">
  #
  # A URL is returned as it is, an unknown name as nothing.
  def image_url(input)
    return input if input.is_a?(String) && input.match?(Nuntius::EmailImages::URL)

    images = Nuntius::EmailImages.in_context(@context)
    image = images.find(input)
    image ? images.url(image, @context.registers["message"]) : ""
  end
end

Liquid::Template.register_filter(ImageUrlFilter)
