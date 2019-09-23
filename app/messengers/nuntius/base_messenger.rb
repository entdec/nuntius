# frozen_string_literal: true

module Nuntius
  # Messengers select templates, can manipulate them and
  class BaseMessenger
    include ActiveSupport::Callbacks

    delegate :liquid_variable_name_for, :class_name_for, to: :class

    define_callbacks :action, terminator: ->(target, result_lambda) { result_lambda.call == false }

    attr_reader :templates, :attachments

    def initialize(object, event, params = {})
      @object = object
      @event = event
      @params = params
      @attachments = []
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
        msg = template.new_message(@object, liquid_context)

        # Needed because the message is not saved yet
        msg.future_attachments = attachments

        transport = Nuntius::BaseTransport.class_from_name(template.transport).new
        transport.deliver(msg)
      end
    end

    #
    # Attaches a file to the message
    #
    # @param url [String] Attachment url, can be file::// protocol too
    # @param auto_zip [true, false] Whether to auto-zip, off by default
    def attach(url, auto_zip: false)
      @attachments ||= []

      attachment = {}
      uri = URI.parse(url)
      if uri.scheme == 'file'
        attachment[:io] = File.open(uri.path)
      else
        client = HTTPClient.new
        response = client.get(url, follow_redirect: true)
        attachment[:content_type] = response.content_type
        if response.body.is_a? String
          attachment[:io] = StringIO.new(response.body)
        else
          # Assume IO object
          attachment[:io] = response.body
        end
      end

      attachment[:filename] ||= uri.path.split('/').last
      attachment[:io] = attachment[:content].read if attachment[:content].respond_to?(:read)

      if auto_zip && attachment[:io].size > 1024 * 1024
        zip_stream = Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry attachment[:file_name]
          zio.write attachment[:content].read
        end
        attachment[:mime_type] = 'application/zip'
        attachment[:io] = zip_stream
      end

      @attachments << attachment
      @attachments
    rescue StandardError => e
      Nuntius.config.logger.error "Message: Could not attach #{attachment[:filename]} #{e.message}"
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
        else
          obj.class.name.demodulize.underscore
        end
      end

      def class_name_for(obj)
        if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
          obj.first.class.name.demodulize
        else
          obj.class.name
        end
      end

      def messenger_for_class(name)
        messenger_name_for_class(name).safe_constantize
      end

      def messenger_name_for_class(name)
        "#{name}Messenger"
      end

      def messenger_for_obj(obj)
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

      @templates = Template.unscoped.where(klass: class_name_for(@object), event: @event).where(enabled: true)

      # See if we need to do something additional
      template_scope_proc = self.class.template_scope
      @templates = @templates.instance_exec(@object, &template_scope_proc) if template_scope_proc

      @templates
    end

    def liquid_context
      assigns = @params || {}
      instance_variables.reject { |i| %w[@params @object @locale @templates @template_scope].include? i.to_s }.each do |i|
        assigns[i.to_s[1..-1]] = instance_variable_get(i)
      end

      assigns.merge(liquid_variable_name_for(@object) => @object)
    end
  end
end
