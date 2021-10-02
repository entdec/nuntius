# frozen_string_literal: true

module Nuntius
  # Messengers select templates, can manipulate them and
  class BaseMessenger
    include ActiveSupport::Callbacks

    delegate :liquid_variable_name_for, :class_name_for, :class_names_for, :event_name_for, to: :class

    define_callbacks :action, terminator: ->(_target, result_lambda) { result_lambda.call == false }

    attr_reader :templates, :attachments, :event, :object, :params

    def initialize(object, event, params = {})
      @object = object
      @event = event
      @params = params
      @attachments = params.fetch(:attachments, [])
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
        @attachments.each do |attachment|
          msg.add_attachment(attachment)
        end

        transport = Nuntius::BaseTransport.class_from_name(template.transport).new
        transport.deliver(msg) if msg.to.present?
      end
    end

    # Allow messengers to override the selected layout
    def override_layout(selected_layout)
      selected_layout
    end

    def attach(attachment)
      @attachments << attachment
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
        return obj.keys.first.to_s if obj.is_a?(Hash)

        plural = obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
        list   = plural ? obj : [obj]
        klass  = list.first.class
        klass  = klass.base_class if klass.respond_to?(:base_class)
        name   = klass.name.demodulize
        name   = name.pluralize if plural
        name.underscore
      end

      def class_name_for(obj)
        if obj.is_a?(Array) || obj.is_a?(ActiveRecord::Relation)
          obj.first.class.name.demodulize
        elsif obj.is_a?(Hash)
          'Custom'
        elsif obj.is_a?(Class)
          obj.name.demodulize
        else
          obj.class.name
        end
      end

      def class_names_for(obj)
        main_class_name = class_name_for(obj)

        return [main_class_name] if !obj.class.respond_to?(:base_class?) || obj.class.base_class?

        list = [main_class_name]
        list << obj.class.base_class.name
        list
      end

      def event_name_for(obj, event)
        if obj.is_a?(Hash)
          "#{obj.keys.first}##{event}"
        else
          event
        end
      end

      def messenger_for_class(name)
        klass = messenger_name_for_class(name).safe_constantize
        klass ||= messenger_name_for_class(name.safe_constantize.superclass).safe_constantize
        klass ||= messenger_name_for_class(name.safe_constantize.superclass.superclass).safe_constantize
        klass
      end

      def messenger_name_for_class(name)
        "#{name}Messenger"
      end

      def messenger_for_obj(obj)
        return Nuntius::CustomMessenger if obj.is_a? Hash

        klass = messenger_name_for_obj(obj).safe_constantize

        # Lets check 2 levels above to see if a messager exists for a possible super class (think STI)
        klass ||= messenger_name_for_obj(obj.class.superclass).safe_constantize
        klass ||= messenger_name_for_obj(obj.class.superclass.superclass).safe_constantize

        raise Nuntius::MissingMessengerException.new(self), "messenger missing for #{obj.class.name}" unless klass

        klass
      end

      def messenger_name_for_obj(obj)
        "#{class_name_for(obj)}Messenger"
      end

      def locale(locale = nil)
        @locale = locale if locale
        @locale
      end

      def template_scope(template_scope = nil)
        @template_scope = template_scope if template_scope
        @template_scope
      end

      def timebased_scopes
        @timebased_scopes ||= {}
      end

      def timebased_scope(name, &scope_proc)
        raise ArgumentError, 'timebased_scope must start with before or after' unless %w[before after].detect { |prefix| name.to_s.start_with?(prefix) }

        name = name.to_sym
        timebased_scopes[name] = scope_proc if scope_proc.present?
        define_method(name) { |object, params = {}| } unless respond_to?(name)
        timebased_scopes[name] || nil
      end

      def timebased_scope_for(template)
        return [] unless timebased_scopes.include?(template.event.to_sym)

        timebased_scope(template.event)
          .call(template.interval_time_range, template.metadata)
          .where("#{template.klass.constantize.table_name}.created_at > ?", template.created_at)
          .where.not(
            id: Nuntius::Message.select(:nuntiable_id)
                                .where(template_id: template.id)
          )
      end
    end

    private

    # Returns the relevant templates for the object / event combination
    def select_templates
      return @templates if @templates

      @templates = Template.unscoped.where(klass: class_names_for(@object), event: event_name_for(@object, @event)).where(enabled: true)
      @templates = @templates.instance_exec(@object, &Nuntius.config.default_template_scope)

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

      context = { liquid_variable_name_for(@object) => (@object.is_a?(Hash) ? @object[@object.keys.first].deep_stringify_keys : @object) }
      assigns.merge(context)
    end
  end
end
