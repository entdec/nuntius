# frozen_string_literal: true

require 'mail'

module Nuntius
  class MailDriver < BaseDriver
    adapter :mail

    # html, text, attachments

    def send(to)
      mail = Mail.new(from: config['from_header'])
      mail.delivery_method :smtp, address: config['host'], port: config['port'], user_name: config['username'], password: config['password']

      mail.to = remove_plus_notations(to).join(',')
      mail.subject = "#{environment_string}#{tpl(:subject, obj, context)}"
      mail.part content_type: 'multipart/alternative' do |p|
        p.html_part = Mail::Part.new(
          body: tpl(:text, obj, context),
          content_type: 'text/plain',
          charset: 'UTF-8'
        )
        if html.present?
          p.text_part = Mail::Part.new(
            body: html_body(config, subj, obj, context),
            content_type: 'text/html',
            charset: 'UTF-8'
          )
        end
      end

      # attachments: [
      #   { file_name: 'test', content_type: 'text/plain', content: 'binary data', file_path: '.../tmp/filetosend.ext', auto_zip: false }
      # ]
      opts.fetch(:attachments, []).each do |attachment|
        attach_file_to_mail(mail, message_instance, attachment)
      end

      # passed as parameters
      opts.fetch(:attachment_urls, []).each do |attachment_url|
        attach_file_to_mail(mail, message_instance, file_url: attachment_url)
      end

      # saved on the message itself
      tpl(:attachment_urls, obj, context).split(/[\n,\s]+/).compact.each do |attachment_url|
        attach_file_to_mail(mail, message_instance, file_url: attachment_url)
      end

      mail.deliver!
    end

    private

    def html_body(config, subj, obj, context = {})
      if config['new_style']

        assigns = { subj => obj, 'message' => self, 'id' => obj.try(:id) }.merge(context).stringify_keys
        registers = {}
        result = render_with_liquid(self, :html, assigns, registers)

        output = Inky::Core.new.release_the_kraken(result)
        Premailer.new(output, with_html_string: true).to_inline_css
      else
        tpl(:html, obj, context)
      end
    end

    def attach_file_to_mail(mail, message_instance, attachment)
      if attachment[:file_url].present?
        attachment[:file_name] ||= attachment[:file_url].split('/').last
        attachment[:content_type] ||= MIME::Types.type_for(attachment[:file_name]).first&.content_type
        attachment[:content] = open(attachment[:file_url]) # rubocop:disable Security/Open
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
