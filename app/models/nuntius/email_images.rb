# frozen_string_literal: true

module Nuntius
  # The images an email design refers to by name: a layout's image
  # attachments, or a template's or campaign's own images and then its
  # layout's. Uploads get a name unique to the record (unique_filename);
  # among older duplicates the first uploaded one wins.
  #
  # An image field in the editor keeps the name in its data (data.image,
  # data.background), and the email refers to it with Liquid, which finds
  # the image when the email is sent:
  #
  #   {{ 'logo.png' | image_url }}     linked, on Nuntius' host for the message
  #   {{ 'logo.png' | embed_image }}   sent with the email
  #
  # Designs from before names kept an image's signed id and its URL. find
  # takes those too, and normalize turns them into names.
  class EmailImages
    # The editor's image fields: where the name is, the attribute the image's
    # URL goes in, and where the image comes from ("upload" or "web")
    FIELDS = [
      {image: "image", url: "src", source: "source"},
      {image: "background", url: "background-url", source: "backgroundSource"}
    ].freeze
    # An Active Storage blob URL, with the blob's signed id
    BLOB_URL = %r{/blobs/(?:redirect/|proxy/)?([^/?#]+)/[^/?#]+(?:[?#].*)?\z}
    URL = %r{\A[a-z][a-z0-9+.-]*://}i

    attr_reader :record

    # The record whose images a Liquid render uses: the template or campaign
    # being sent
    def self.in_context(context)
      registers = context.registers
      message = registers["message"]
      new(registers["template"] || registers["campaign"] || message&.template || message&.campaign)
    end

    # URL options for an image on a host as Nuntius.config.host gives it
    # (example: https://app.example.com or app.example.com)
    def self.url_options(host)
      return {} if host.blank?

      host.include?("://") ? {host: host, port: nil} : {host: host, protocol: "https", port: nil}
    end

    def initialize(record)
      @record = record
    end

    # Its images, one per name
    def images
      Array(record&.email_images)
    end

    # The image a name refers to, or (in older designs) a signed id or a
    # blob URL of one of its images
    def find(reference)
      return if reference.blank? || !reference.is_a?(String)

      images.find { |image| image.filename.to_s == reference } || find_blob(reference)
    end

    # Where an image is loaded from, on Nuntius' host for the message
    def url(image, message = nil, **options)
      options = self.class.url_options(Nuntius.config.host(message)) if options.empty?
      return Rails.application.routes.url_helpers.rails_blob_path(image) unless options[:host]

      Rails.application.routes.url_helpers.rails_blob_url(image, **options)
    end

    # A name for a new image that none of its images (nor, for a layout, its
    # emails' images) has yet: logo.png, then logo-2.png, logo-3.png, ...
    # Quotes are left out, as the name goes in a Liquid string.
    def unique_filename(filename)
      filename = ActiveStorage::Filename.new(filename.to_s.delete(%q('"))).sanitized
      filename = "image" if filename.blank?
      taken = taken_names
      return filename unless taken.include?(filename)

      base, extension = File.basename(filename, ".*"), File.extname(filename)
      (2..).lazy.map { |number| "#{base}-#{number}#{extension}" }.find { |name| !taken.include?(name) }
    end

    # The document (or nodes) with names in its image fields. With url
    # options each field's URL is the image's (for the editor's canvas),
    # without them it is left out (it is stored with the name only). An
    # older reference that is no longer one of its images becomes a web
    # image, so its URL stays as it was.
    def normalize(json, **url_options)
      json = json.deep_dup
      each_node(json) { |node| normalize_node(node, url_options) }
      json
    end

    private

    def find_blob(reference)
      signed_id = reference.match?(URL) ? reference[BLOB_URL, 1] : reference
      blob = signed_id && ActiveStorage::Blob.find_signed(signed_id)
      blob && images.find { |image| image.blob_id == blob.id }
    end

    def taken_names
      names = attachments_of(record)
      names += record.templates.flat_map { |email| attachments_of(email) } + record.campaigns.flat_map { |email| attachments_of(email) } if record.is_a?(Layout)
      names += attachments_of(record.layout) if record.respond_to?(:layout) && record.layout
      names.to_set
    end

    def attachments_of(owner)
      (owner.is_a?(Layout) ? owner.attachments : owner.images).map { |attachment| attachment.filename.to_s }
    end

    def each_node(json, &block)
      case json
      when Array then json.each { |node| each_node(node, &block) }
      when Hash
        yield json
        Array(json["children"]).each { |child| each_node(child, &block) }
      end
    end

    def normalize_node(node, url_options)
      data = node["data"]
      return unless data.is_a?(Hash)

      FIELDS.each do |field|
        reference = data[field[:image]]
        next if reference.blank? || data[field[:source]] == "web"

        attributes = (node["attributes"] ||= {})
        if (image = find(reference.to_s))
          data[field[:image]] = image.filename.to_s
          data[field[:source]] = "upload"
          url_options.empty? ? attributes.delete(field[:url]) : attributes[field[:url]] = url(image, **url_options)
        elsif attributes[field[:url]].present?
          data.delete(field[:image])
          data[field[:source]] = "web"
        end
      end
    end
  end
end
