# frozen_string_literal: true

# This class allows us to send any type of message to our users
# At this time messages can either be email, sms, push
# All of the templating is done using liquid
#
class Message < ApplicationRecord
  include TemplateBasics

  belongs_to :layout, class_name: 'Message', optional: true

  has_many :message_instances, dependent: :destroy

  policy_scopes

  validates :conditions, liquid: true
  validates :subject, liquid: true
  validates :html, liquid: true
  validates :text, liquid: true

  def self.timestamp_based
    where.not(timestamp: [nil, '']).where.not(interval: nil).where(event: [nil, ''])
  end

  # Processes the message in the background queue
  def process(obj, opts)
    Rails.logger.debug "Message '#{description}' (#{id}) processing for #{obj.class.name} - #{obj.try(:id)}, kind: #{kind}"

    return unless applicable?(obj)

    Rails.logger.debug "Message '#{description}' (#{id}) is applicable #{obj.class.name} - #{obj.try(:id)}, kind: #{kind}"

    case kind
    when 'email'
      send_mail(obj, opts)
    when 'sms'
      send_sms(obj, opts) unless ENV['MESSAGING_OVERRIDE'].present?
    when 'push'
      send_push(obj, opts) unless ENV['MESSAGING_OVERRIDE'].present?
    end
  end

  private

  def send_mail(obj, opts)
    with_message_instance(obj) do |message_instance|
      subj = obj.class.name.split('::').last.underscore
      context = opts.delete(:context) || {}
      config = channel.settings_hash(:mail)
      config['whitelisted_domains'] = config['whitelisted_domains'] || %w[degrunt.nl boxture.com bratelement.com itsmeij.com]

      # We remove all newline characters
      to = tpl(:to, obj, context).tr("\n", '').split(',')
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

        mail = channel.new_mail
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

        message_instance.state = :sent
        message_instance.protocol_id = mail.message_id
        message_instance.content_type = 'text/html'
        message_instance.body = mail.html_part&.decoded
      end
    end
  end

  def send_sms(obj, opts)
    context = opts.delete(:context) || {}
    config = obj.channel.settings_hash('twilio')
    config['whitelisted_phonenumbers'] ||= %w[+31641085630]

    to = tpl(:to, obj, context).split(',')
    to = to.reject { |e| e.include?('+31611223344') }.uniq
    to = to.reject { |e| !Rails.env.production? && config['whitelisted_phonenumbers'].none? { |w| e.include?(w) } }.uniq

    Rails.logger.info "SMS Message '#{description}' (#{id}) will be sent to: #{to.join(',')}"
    client = Twilio::REST::Client.new(config['sid'], config['auth_token'])
    send_sms_value = to.each do |to_number|
      with_message_instance(obj) do |message_instance|
        message_instance.body = "#{environment_string}#{tpl(:text, obj, context)}"
        message_instance.content_type = 'text/plain'
        response = client.messages.create(from: config['phone_number'], to: to_number, body: "#{environment_string}#{tpl(:text, obj, context)}")
        message_instance.protocol_id = response.sid
        message_instance.state = :pending
        ProcessTwilioMessageStatusJob.call(message_instance)
      end
    end
    send_sms_value if to.present?
  end

  def send_push(obj, opts)
    with_message_instance(obj) do |message_instance|
      channel = obj.channel
      subj = obj.class.name.split('::').last.underscore
      context = opts.delete(:context) || {}
      ios_config = channel.settings_hash(:apple_push)
      android_config = channel.settings_hash(:firebase)

      to = tpl(:to, obj, context).split(',').uniq.map(&:to_s)
      users = User.where(id: to)

      body = "#{environment_string}#{tpl(:text, obj, context)}"

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
        apn = Rails.env.production? ? Houston::Client.production : Houston::Client.development
        apn.certificate = ios_config['certificate'] + "\n" + ios_config['key']
        # See https://console.firebase.google.com/project/<project>/settings/cloudmessaging
        fcm = FCM.new(android_config['server_key'])

        ios_devices = []
        android_devices = []
        users.each do |user|
          next if user.ios_devices.to_a.empty? && user.android_devices.to_a.empty?

          ios_devices += user.ios_devices.to_a
          android_devices += user.android_devices.to_a
        end
        ios_devices.uniq!
        android_devices.reject { |d| d.starts_with?('APA91b') }.uniq!

        ios_devices.each do |token|
          notification = Houston::Notification.new(device: token)
          notification.alert = body
          notification.badge = 0
          notification.sound = 'default'
          apn.push(notification)
        end

        if android_devices.present?
          options = { data: { body: body } }
          response = fcm.send(android_devices, options)
          raise "FCM said: #{response[:status_code]} / #{response[:response]}" if response[:status_code] != 200 || response[:response] != 'success'
        end
        message_instance.state = :sent
      end
    end
  end

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
    Rails.logger.error "Message: #{e.message}: #{e.backtrace.join('; ')}"
  end

  def message_instance_for(obj)
    base = obj if obj.respond_to?(:message_instances)
    base ||= obj.shipment if obj.respond_to?(:shipment)
    base ||= obj.user if obj.respond_to?(:user)
    return base.message_instances.create(message: self, state: :sending) if base

    # Returning a blank instance if no message instance present, this way we can keep state but we will not save it.
    MessageInstance.new(message: self)
  end

  def render_with_liquid(message, attr, assigns, registers)
    template = Liquid::Template.parse(message.send(attr))
    result = template.render(assigns, registers: registers)

    assigns = template.assigns.stringify_keys
    registers = template.registers.stringify_keys

    result = Tilt[message.filter].new { result }.render if message.filter.present?
    if message.layout
      registers['_yield'] = {} unless registers['_yield']
      registers['_yield'][''] = result.delete("\n")
      result = render_with_liquid(message.layout, attr, assigns, registers)
    end
    result
  end
end
