# frozen_string_literal: true

# This class allows us to send any type of message to our users
# At this time messages can either be email, sms, push
# All of the templating is done using liquid
#
class Message < ApplicationRecord
  has_paper_trail

  amoeba do
    enable
    prepend description: 'Copy of '
  end

  include TemplateBasics

  belongs_to :channel
  belongs_to :company
  belongs_to :retailer
  belongs_to :layout, class_name: 'Message'

  has_many   :message_instances, dependent: :destroy

  policy_scopes

  validates :conditions, liquid: true
  validates :subject, liquid: true
  validates :html, liquid: true
  validates :text, liquid: true

  def self.timestamp_based
    where.not(timestamp: [nil, '']).where.not(interval: nil).where(event: [nil, ''])
  end

  # Processes the message in the background queue
  def process_with_object(obj, opts)
    Rails.logger.debug "Message '#{description}' (#{id}) processing for #{obj.class.name} - #{obj.id}, kind: #{kind}"

    return unless applicable_with_object?(obj)

    Rails.logger.debug "Message '#{description}' (#{id}) is applicable #{obj.class.name} - #{obj.id}, kind: #{kind}"

    case kind
    when 'email'
      send_mail_with_object(obj, opts)
    when 'sms'
      send_sms_with_object(obj, opts) unless ENV['MESSAGING_OVERRIDE'].present?
    when 'push'
      send_push_with_object(obj, opts) unless ENV['MESSAGING_OVERRIDE'].present?
    end
  end

  # TODO: Allow additional context to be passed
  def tpl(attr, subj, inst, additional_context = {})
    context = { subj => inst, 'message' => self, 'id' => (inst.respond_to?(:id) ? inst.id : '') }.merge(additional_context || {}).stringify_keys
    base = Liquid::Template.parse(send(attr))
    result = base.render(context)
    if context['_layout'].present?
      m = Message.where(subject: "_layout:#{context['_layout']}").first
      if m.present?
        context['yield'] = result
        context.merge!(base.instance_assigns)
        layout = Liquid::Template.parse(m.send(attr))
        result = layout.render(context)
      end
    end
    result
  end

  def send_mail_with_object(obj, opts)
    with_message_instance(obj) do |message_instance|
      subj                          = obj.class.name.downcase.split('::').last
      context                       = opts.delete(:context) || {}
      config                        = channel.settings['mail']
      config['whitelisted_domains'] = config['whitelisted_domains'] || %w[degrunt.nl boxture.com bratelement.com itsmeij.com]

      # We remove all newline characters
      to = tpl(:to, subj, obj, context).tr("\n", '').split(',')
      Rails.logger.debug "Message '#{description}' (#{id}) full address list: #{to.join(',')}"
      to = to.reject { |e| e.include?('@example.com') || e.empty? }.uniq
      to = to.reject { |e| !Rails.env.production? && config['whitelisted_domains'].none? { |w| e.include?("@#{w}") } }.uniq unless %w[User Importo::Import].include?(obj.class.name)
      to = [ENV['MESSAGING_OVERRIDE']] if ENV['MESSAGING_OVERRIDE'].present?

      if to.empty?
        # Did not find an email address to send to, but lets log the would be body anyway.
        message_instance.body = html_body(config, subj, obj, context)
        message_instance.content_type = 'text/html'
        message_instance.state = :no_whitelisted_to_address
      else
        Rails.logger.debug "Message '#{description}' (#{id}) will be sent to: #{to.join(',')}"

        mail         = channel.new_mail
        mail.to      = remove_plus_notations(to).join(',')
        mail.subject = "#{environment_string}#{tpl(:subject, subj, obj, context)}"
        mail.part content_type: 'multipart/alternative' do |p|
          p.html_part = Mail::Part.new(
            body:         tpl(:text, subj, obj, context),
            content_type: 'text/plain',
            charset:      'UTF-8'
          )
          p.text_part = Mail::Part.new(
            body:         html_body(config, subj, obj, context),
            content_type: 'text/html',
            charset:      'UTF-8'
          )
        end

        # attachments: [
        #   { file_name: 'test', content_type: 'text/plain', content: 'binary data', file_path: '.../tmp/filetosend.ext', auto_zip: false }
        # ]
        opts.fetch(:attachments, []).each do |attachment|
          attach_file_to_mail(mail, attachment)
        end

        mail.deliver!

        message_instance.state = :sent
        message_instance.protocol_id = mail.message_id
        message_instance.content_type = 'text/html'
        message_instance.body = mail.html_part&.decoded
      end
    end
  end

  def attach_file_to_mail(mail, attachment)
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
  end

  def send_sms_with_object(obj, opts)
    subj    = obj.class.name.downcase
    context = opts.delete(:context) || {}
    config  = obj.channel.settings['twilio']
    config['whitelisted_phonenumbers'] ||= %w[+31641085630]

    to = tpl(:to, subj, obj, context).split(',')
    to = to.reject { |e| e.include?('+31611223344') }.uniq
    to = to.reject { |e| !Rails.env.production? && config['whitelisted_phonenumbers'].none? { |w| e.include?(w) } }.uniq

    send_sms(obj, config, to, "#{environment_string}#{tpl(:text, subj, obj, context)}") if to.present?
  end

  def send_sms(obj, config, to, body)
    Rails.logger.info "SMS Message '#{description}' (#{id}) will be sent to: #{to.join(',')}"
    client = Twilio::REST::Client.new(config['sid'], config['auth_token'])
    to.each do |to_number|
      with_message_instance(obj) do |message_instance|
        message_instance.body = body
        message_instance.content_type = 'text/plain'
        response = client.messages.create(from: config['phone_number'], to: to_number, body: body)
        message_instance.protocol_id = response.sid
        message_instance.state = :pending
        ProcessTwilioMessageStatusJob.perform_later(message_instance)
      end
    end
  end

  def send_push_with_object(obj, opts)
    with_message_instance(obj) do |message_instance|
      channel        = obj.channel
      subj           = obj.class.name.downcase
      context        = opts.delete(:context) || {}
      ios_config     = channel.settings['apple_push']
      android_config = channel.settings['firebase']

      to = tpl(:to, subj, obj, context).split(',')
      to = to.uniq.map(&:to_s)
      users = User.where('id = ANY(ARRAY[?]::uuid[])', to) unless to.empty?

      body = "#{environment_string}#{tpl(:text, subj, obj, context)}"

      message_instance.body = body
      message_instance.content_type = 'text/plain'

      if users.empty?
        message_instance.state = :no_whitelisted_to_address
      elsif !Rails.env.production? && !Rails.env.staging? && !Rails.env.test?
        Rails.logger.debug "Non production/staging - Message would have been sent to: #{to.join(',')}"
        message_instance.state = :not_production
      else
        Rails.logger.debug "Message '#{description}' (#{id}) will be sent to: #{to.join(',')}"
        Rails.logger.debug "Message '#{description}' (#{id}) will be sent to: #{users.map(&:email)}"
        Rails.logger.debug "Message '#{description}' (#{id}) contents: #{body}"

        # Only in production, with the AppStore app will we use production
        # and the production certificate
        apn             = Rails.env.production? ? Houston::Client.production : Houston::Client.development
        apn.certificate = ios_config['certificate'] + "\n" + ios_config['key']
        # See https://console.firebase.google.com/project/<project>/settings/cloudmessaging
        fcm = FCM.new(android_config['server_key'])

        ios_devices     = []
        android_devices = []
        users.each do |user|
          next if user.ios_devices.to_a.empty? && user.android_devices.to_a.empty?
          ios_devices     += user.ios_devices.to_a
          android_devices += user.android_devices.to_a
        end
        ios_devices.uniq!
        android_devices.reject { |d| d.starts_with?('APA91b') }.uniq!

        ios_devices.each do |token|
          notification       = Houston::Notification.new(device: token)
          notification.alert = body
          notification.badge = 0
          notification.sound = 'default'
          apn.push(notification)
        end

        if android_devices.present?
          options  = { data: { body: body } }
          response = fcm.send(android_devices, options)
          raise "FCM said: #{response[:status_code]} / #{response[:response]}" if response[:status_code] != 200 || response[:response] != 'success'
        end
        message_instance.state = :sent
      end
    end
  end

  private

  def remove_plus_notations(to)
    to.map { |e| e.match?(/.*\+.*postnl\.nl$/) ? "#{e.split('+').first}@#{e.split('@').last}" : e }
  end

  def with_message_instance(obj)
    message_instance = message_instance_for(obj)
    message_instance.request_id = Praesens.request_id
    yield message_instance
    # Dont save the instance if it does not belong to the object
    message_instance.save if message_instance.persisted?
  rescue StandardError => e
    message_instance.state = :failed
    message_instance.feedback = { type: 'Error', info: e.message }
    message_instance.save if message_instance.persisted?
  end

  def message_instance_for(obj)
    base = obj if obj.respond_to?(:message_instances)
    base ||= obj.shipment if obj.respond_to?(:shipment)
    base ||= obj.user if obj.respond_to?(:user)
    return base.message_instances.create(message: self, state: :sending) if base

    # Returning a blank instance if no message instance present, this way we can keep state but we will not save it.
    MessageInstance.build(message.self)
  end

  def html_body(config, subj, obj, context = {})
    if config['new_style']

      assigns = { subj => obj, 'message' => self, 'id' => (obj.respond_to?(:id) ? obj.id : '') }.merge(context).stringify_keys
      registers = {}
      result = render_with_liquid(self, :html, assigns, registers)

      output = Inky::Core.new.release_the_kraken(result)
      Premailer.new(output, with_html_string: true).to_inline_css
    else
      tpl(:html, subj, obj, context)
    end
  end

  def render_with_liquid(message, attr, assigns, registers)
    template = Liquid::Template.parse(message.send(attr))
    result   = template.render(assigns, registers: registers)

    assigns   = template.assigns.stringify_keys
    registers = template.registers.stringify_keys

    result    = Tilt[message.filter].new { result }.render if message.filter.present?
    if message.layout
      registers['_yield']     = {} unless registers['_yield']
      registers['_yield'][''] = result.delete("\n")
      result                  = render_with_liquid(message.layout, attr, assigns, registers)
    end
    result
  end
end
