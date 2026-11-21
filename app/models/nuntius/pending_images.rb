# frozen_string_literal: true

module Nuntius
  # Images uploaded in the email editor of a layout, template or campaign
  # that isn't saved yet (Admin::MediaController). Each is a blob marked
  # pending in its metadata, which the editor refers to by its signed id
  # until the record is created: the record then attaches those its design
  # refers to, under a name of its own (EmailImages#unique_filename), and
  # refers to them by that name from then on.
  #
  # Those never attached, their record never saved, are left for the host
  # app to purge: unattached blobs with "pending" => true in their metadata.
  class PendingImages
    KEY = "pending"

    attr_reader :record

    # An image for a record that isn't saved yet
    def self.upload(file, filename:)
      ActiveStorage::Blob.create_and_upload!(io: file, filename: filename, content_type: file.content_type, metadata: {KEY => true}, **{service_name: Nuntius.config.active_storage_service}.compact)
    end

    # The pending blob a reference (a signed id) is, while it isn't attached
    def self.find(reference)
      return unless reference.is_a?(String) && reference.present?

      blob = ActiveStorage::Blob.find_signed(reference)
      blob if blob && blob.metadata[KEY] && !blob.attachments.exists?
    end

    def initialize(record)
      @record = record
    end

    # Attaches the pending images its design refers to, and refers to them by
    # their names instead: in its document, its MJML and its HTML
    def attach
      names = {}
      email_images = EmailImages.new(record)
      each_reference(record.json) do |reference|
        next if names.key?(reference) || !(blob = self.class.find(reference))

        # Its record's from now on, no longer pending
        name = email_images.unique_filename(blob.filename.to_s)
        blob.update!(filename: name, metadata: blob.metadata.except(KEY))
        uploads.attach(blob)
        names[reference] = name
      end
      rename(names) if names.any?
    end

    private

    def uploads
      record.is_a?(Layout) ? record.attachments : record.images
    end

    def each_reference(json, &block)
      case json
      when Array then json.each { |node| each_reference(node, &block) }
      when Hash
        data = json["data"]
        EmailImages::FIELDS.each { |field| yield data[field[:image]] if data.is_a?(Hash) && data[field[:image]].is_a?(String) } if data
        Array(json["children"]).each { |child| each_reference(child, &block) }
      end
    end

    def rename(names)
      record.json = rename_in_json(record.json.deep_dup, names)
      %i[mjml html].each do |attribute|
        text = record.public_send(attribute)
        next if text.blank?

        record.public_send(:"#{attribute}=", names.reduce(text) { |renamed, (reference, name)| renamed.gsub("'#{reference}'", "'#{name}'") })
      end
    end

    def rename_in_json(json, names)
      case json
      when Array then json.each { |node| rename_in_json(node, names) }
      when Hash
        data = json["data"]
        EmailImages::FIELDS.each { |field| data[field[:image]] = names[data[field[:image]]] if names.key?(data[field[:image]]) } if data.is_a?(Hash)
        Array(json["children"]).each { |child| rename_in_json(child, names) }
      end
      json
    end
  end
end
