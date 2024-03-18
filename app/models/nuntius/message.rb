# frozen_string_literal: true

require "pry"
module Nuntius
  # Stores individual messages to individual recipients
  #
  #
  # Nuntius will have messages in states:
  #   pending - nothing done yet
  #   sent - we've sent it on to the provider
  #   delivered - have delivery confirmation
  #   undelivered - have confirmation of non-delivery
  # Not all transports may provide all states
  class Message < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped

    has_and_belongs_to_many :attachments, class_name: "Attachment"

    belongs_to :campaign, optional: true
    belongs_to :template, optional: true
    belongs_to :parent_message, class_name: "Message", optional: true
    has_many :child_messages, class_name: "Message", foreign_key: "parent_message_id", dependent: :destroy
    belongs_to :nuntiable, polymorphic: true, optional: true

    validates :transport, presence: true

    before_destroy :cleanup_attachments

    # Weird loading sequence error, is fixed by the lib/nuntius/helpers
    # begin
    #   has_many_attached :attachments
    # rescue NoMethodError
    # end

    def pending?
      status == "pending"
    end

    def sent?
      status == "sent"
    end

    def blocked?
      status == "blocked"
    end

    def delivered?
      status == "delivered"
    end

    def delivered_or_blocked?
      delivered? || blocked?
    end

    def undelivered?
      status == "undelivered"
    end

    # Removes only pending child messages
    def cleanup!
      Nuntius::Message.where(status: "pending").where(parent_message: self).destroy_all
    end

    def add_attachment(options)
      attachment = {}

      uri = options[:url] && URI.parse(options[:url])

      if uri&.scheme == "file"
        # FIXME: This is a possible security problem
        attachment[:io] = File.open(uri.path)
      elsif uri
        client = Faraday.new(ssl: {verify: false}) do |builder|
          builder.response :follow_redirects
          builder.adapter Faraday.default_adapter
        end

        response = client.get(options[:url])
        content_disposition = response.headers["Content-Disposition"] || ""

        options[:filename] ||= content_disposition[/filename="([^"]+)"/, 1]
        attachment[:content_type] = response.headers["Content-Type"]
        attachment[:io] = if response.body.is_a? String
          StringIO.new(response.body)
        else
          # Assume IO object
          response.body
        end
      elsif options[:content].respond_to?(:read)
        attachment[:content_type] = options[:content_type]
        attachment[:io] = options[:content]
      else
        raise "Cannot add attachment without url or content"
      end

      # Set the filename
      attachment[:filename] = options[:filename] || uri.path.split("/").last || "attachment"

      # (Try to) add file extension if it is missing
      file_extension = File.extname(attachment[:filename]).delete(".")
      attachment[:filename] += ".#{Mime::Type.lookup(attachment[:content_type].split(";").first).to_sym}" if file_extension.blank? && attachment[:content_type]

      # Fix content type if file extension known but content type blank
      attachment[:content_type] ||= Mime::Type.lookup_by_extension(file_extension)&.to_s if file_extension

      if options[:auto_zip] && attachment[:io].size > 1024 * 1024
        zip_stream = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry attachment[:file_name]
          zio.write attachment[:io].read
        end
        attachment[:content_type] = "application/zip"
        attachment[:io] = zip_stream
      end

      nuntius_attachment = Nuntius::Attachment.new
      nuntius_attachment.content.attach(io: attachment[:io],
        filename: attachment[:filename],
        content_type: attachment[:content_type])

      attachments.push(nuntius_attachment)
    rescue => e
      Nuntius.config.logger.error "Message: Could not attach #{attachment[:filename]} #{e.message}"
    end

    def cleanup_attachments
      attachments.each do |attachment|
        attachment.destroy if attachment.messages.where.not(id: id).blank?
      end
    end

    def nuntius_provider(message)
      klass = Nuntius::BaseProvider.class_from_name(provider, transport)
      klass ||= Nuntius::BaseProvider
      klass.new(message)
    end

    def resend
      return if pending?
      return unless transport

      deliver_as(transport)
    end

    #
    # Convenience method to easily send messages without having a template
    #
    def deliver_as(transport)
      klass = BaseTransport.class_from_name(transport).new
      klass.deliver(self)
      self
    end
  end
end
