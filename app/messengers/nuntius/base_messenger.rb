# frozen_string_literal: true

module Nuntius
  # Messengers select templates, can manipulate them and
  class BaseMessenger
    include ActiveSupport::Callbacks

    delegate :liquid_variable_name_for, :class_name_for, :event_name_for, to: :class

    define_callbacks :action, terminator: ->(_target, result_lambda) { result_lambda.call == false }

    attr_reader :templates, :attachments, :event, :object, :params

    def initialize(object, event, params = {})
      @object = object
      @event = event
      @params = params
      @attachments = []

      # Allow attachments to be passed directly
      params.fetch(:attachment_urls, []).each { |url| attach(url) }
    end

    # Calls the event method on the messenger
    def call
      select_templates
      run_callbacks(:action) do
        send(@event.to_sym, @object, @params)
      end
    end

    # Turns the templates in messages, and dispatches the messages to transports
    def dispatch(filtered_templates)
      filtered_templates.each do |template|
        template.layout = override_layout(template.layout)
        msg = template.new_message(@object, liquid_context, params)

        # Needed because the message is not saved yet
        msg.future_attachments = attachments

        transport = Nuntius::BaseTransport.class_from_name(template.transport).new
        transport.deliver(msg) if msg.to.present?
      end
    end

    #
    # Attaches a file to the message
    #
    # @param url [String] Attachment url, can be file::// protocol too
    # @param auto_zip [true, false] Whether to auto-zip, off by default
    def attach(url, options = {})
      attachment = {}

      uri = url && URI.parse(url)

      if uri&.scheme == 'file'
        attachment[:io] = File.open(uri.path)
      elsif uri
        client = HTTPClient.new
        response = client.get(url, follow_redirect: true)
        attachment[:content_type] = response.content_type
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
        raise 'Cannot add attachment without url or content'
      end

      # Set the filename
      attachment[:filename] = options[:filename] || uri.path.split('/').last || 'attachment'

      # (Try to) add file extension if it is missing
      file_extension = File.extname(attachment[:filename]).delete('.')
      attachment[:filename] += ".#{Mime::Type.lookup(attachment[:content_type].split(';').first).to_sym}" if file_extension.blank? && attachment[:content_type]

      # Fix content type if file extension known but content type blank
      attachment[:content_type] ||= Mime::Type.lookup_by_extension(file_extension)&.to_s if file_extension

      if options[:auto_zip] && attachment[:io].size > 1024 * 1024
        zip_stream = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry attachment[:file_name]
          zio.write attachment[:io].read
        end
        attachment[:content_type] = 'application/zip'
        attachment[:io] = zip_stream
      end

      @attachments << attachment
      attachment
    rescue StandardError => e
      Nuntius.config.logger.error "Message: Could not attach #{attachment[:filename]} #{e.message}"
    end

    # Allow messengers to override the selected layout
    def override_layout(selected_layout)
      selected_layout
    end

    class << self
      #
      # Returns the variable name used in the liquid context
      #
      # @param [Object] obj Any object with a backing drop
      #
      # @return [String] underscored, lowercase string
      #
      def liquid_variable_name_for(obj)
        if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
          obj.first.class.name.demodulize.pluralize.underscore
        elsif obj.is_a?(Hash)
          obj.keys.first.to_s
        else
          obj.class.name.demodulize.underscore
        end
      end

      def class_name_for(obj)
        if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
          obj.first.class.name.demodulize
        elsif obj.is_a?(Hash)
          'Custom'
        else
          obj.class.name
        end
      end

      def event_name_for(obj, event)
        if obj.is_a?(Hash)
          "#{obj.keys.first}##{event}"
        else
          event
        end
      end

      def messenger_for_class(name)
        messenger_name_for_class(name).safe_constantize
      end

      def messenger_name_for_class(name)
        "#{name}Messenger"
      end

      def messenger_for_obj(obj)
        return Nuntius::CustomMessenger if obj.is_a? Hash

        messenger_name_for_obj(obj).safe_constantize
      end

      def messenger_name_for_obj(obj)
        "#{Nuntius::BaseMessenger.class_name_for(obj)}Messenger"
      end

      def locale(locale = nil)
        @locale = locale if locale
        @locale
      end

      def template_scope(template_scope = nil)
        @template_scope = template_scope if template_scope
        @template_scope
      end
    end

    private

    # Returns the relevant templates for the object / event combination
    def select_templates
      return @templates if @templates

      @templates = Template.unscoped.where(klass: class_name_for(@object), event: event_name_for(@object, @event)).where(enabled: true)
      @templates = @templates.instance_exec(@object, &Nuntius.config.default_template_scope)

      # See if we need to do something additional
      template_scope_proc = self.class.template_scope
      if template_scope_proc
        @templates = @templates.instance_exec(@object, &template_scope_proc)
      end

      @templates
    end

    def liquid_context
      assigns = @params || {}
      instance_variables.reject { |i| %w[@params @object @locale @templates @template_scope].include? i.to_s }.each do |i|
        assigns[i.to_s[1..-1]] = instance_variable_get(i)
      end

      context = { liquid_variable_name_for(@object) => (@object.is_a?(Hash) ? @object[@object.keys.first].deep_stringify_keys : @object) }
      assigns.merge(context)
    end
  end
end
