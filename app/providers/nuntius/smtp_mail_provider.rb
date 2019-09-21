# frozen_string_literal: true

require 'mail'

module Nuntius
  class SmtpMailProvider < BaseProvider
    transport :mail

    setting_reader :from_header, required: true, description: 'From header (example: Nuntius Messenger <nuntius@entdec.com>)'
    setting_reader :host, required: true, description: 'Host (example: smtp.soverin.net)'
    setting_reader :port, required: true, description: 'Port (example: 578)'
    setting_reader :username, required: true, description: 'Username (nuntius@entdec.com)'
    setting_reader :password, required: true, description: 'Password'

    def deliver
      mail = if message.from.present?
               Mail.new(sender: from_header, from: message.from)
             else
               Mail.new(from: from_header)
             end
      mail.delivery_method :smtp,
                           address: host,
                           port: port,
                           user_name: username,
                           password: password,
                           return_response: true

      mail.to = message.to
      mail.subject = message.subject
      mail.part content_type: 'multipart/alternative' do |p|
        p.text_part = Mail::Part.new(
          body: message.text,
          content_type: 'text/plain',
          charset: 'UTF-8'
        )
        if message.html.present?
          message.html = message.html.gsub("%7B&gt;message_url&lt;%7D", message_url(message))
          p.html_part = Mail::Part.new(
            body: message.html,
            content_type: 'text/html',
            charset: 'UTF-8'
          )
        end
      end

      # TODO: attachments - use active_storage
      # Attachments will be stored using active_storage on the message

      # attachments: [
      #   { file_name: 'test', content_type: 'text/plain', content: 'binary data', file_path: '.../tmp/filetosend.ext', auto_zip: false }
      # ]
      # opts.fetch(:attachments, []).each do |attachment|
      #   attach_file_to_mail(mail, message_instance, attachment)
      # end
      #
      # # passed as parameters
      # opts.fetch(:attachment_urls, []).each do |attachment_url|
      #   attach_file_to_mail(mail, message_instance, file_url: attachment_url)
      # end
      #
      # # saved on the message itself
      # tpl(:attachment_urls, obj, context).split(/[\n,\s]+/).compact.each do |attachment_url|
      #   attach_file_to_mail(mail, message_instance, file_url: attachment_url)
      # end
      #
      response = mail.deliver!

      message.provider_id = mail.message_id
      message.status = 'undelivered'
      if response.success?
        # message.provider_id = response.string.split.last
        message.status = 'sent' if response.success?
      end

      message
    end

    private

    def message_url(message)
      Nuntius::Engine.routes.url_helpers.message_url(message.id, host: Nuntius.config.host(message))
    end

    def attach_file_to_mail(mail, message_instance, attachment)
      if attachment[:file_url].present?
        attachment[:file_name] ||= attachment[:file_url].split('/').last

        response = HTTPClient.new.get(attachment[:file_url], follow_redirect: true)
        attachment[:content_type] ||= response.content_type || MIME::Types.type_for(attachment[:file_name]).first&.content_type
        attachment[:content] = response.body
      end

      if attachment[:file_path].present?
        attachment[:file_name] ||= attachment[:file_path].split('/').last
        attachment[:content_type] ||= MIME::Types.type_for(attachment[:file_name]).first&.content_type
        attachment[:content] = File.new(attachment[:file_path])

        FileUtils.rm(attachment[:file_path]) if attachment[:auto_delete]
      end

      attachment[:content] = attachment[:content].read if attachment[:content].respond_to?(:read)

      if attachment[:auto_zip] && attachment[:content].size > 1024 * 1024
        zip_stream = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry attachment[:file_name]
          zio.write attachment[:content]
        end
        attachment[:content_type] = 'application/zip'
        attachment[:content] = zip_stream.string
      end

      mail.attachments[attachment[:file_name].to_s] = { mime_type: attachment[:content_type], content: attachment[:content] }
    rescue StandardError => e
      message_instance.feedback = { type: 'Warning', info: "Could not attach #{attachment[:file_name]} (#{attachment[:file_url] || attachment[:file_path]}) #{e.message}" }
      Rails.logger.error "Message: Could not attach #{attachment[:file_name]} #{e.message}"
    end
  end
end
