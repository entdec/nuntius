# frozen_string_literal: true

module Nuntius
  # Messengers select templates, can manipulate them and
  class BaseMessenger
    include ActiveSupport::Callbacks

    delegate :liquid_variable_name_for, :class_name_for, :class_names_for, :event_name_for, to: :class

    define_callbacks :action, terminator: ->(_target, result_lambda) { result_lambda.call == false }

    attr_reader :attachments, :headers, :event, :object, :params
    attr_writer :templates
    attr_accessor :smtp_envelope_from

    def initialize(object, event, params = {})
      @object = object
      @event = event
      @params = params
      @attachments = params.fetch(:attachments, [])
      @headers = params.fetch(:headers, {})
      @smtp_envelope_from = params[:smtp_envelope_from]
    end

    # Calls the event method on the messenger
    def call
      select_templates
      result = nil
      run_callbacks(:action) do
        result = send(@event.to_sym, @object, @params) if respond_to?(@event.to_sym)
      end
      result
    end

    # Turns the templates in messages, and dispatches the messages to
    # transports: those whose conditions are met
    def dispatch(filtered_templates)
      filtered_templates.each do |template|
        assigns = liquid_context
        next unless template.conditions_met?(assigns.merge("template" => template))

        template.layout = override_layout(template.layout)
        msg = template.new_message(@object, assigns, params, account: account)
        next unless msg.present?

        @attachments.each do |attachment|
          msg.add_attachment(attachment)
        end
        apply_mail_overrides(msg)

        transport = Nuntius::BaseTransport.class_from_name(template.transport).new
        transport.deliver(msg)
      end
    end

    # Whether it sends the template: the object's account sends with it, and
    # its conditions are met
    def sends?(template)
      templates.exists?(template.id) && template.conditions_met?(liquid_context.merge("template" => template))
    end

    # Allow messengers to override the selected layout
    def override_layout(selected_layout)
      selected_layout
    end

    def attach(attachment)
      @attachments << attachment
    end

    # Sets an extra header on the resulting message (currently applied by the
    # mail transport). Useful for things like "Auto-Submitted" or "Precedence".
    def header(key, value)
      @headers[key.to_s] = value
    end

    # The templates for the object and event: see select_templates
    def templates
      select_templates
    end

    # The account the messenger sends for: from the messenger's account proc, or
    # Nuntius.config.account_for
    def account
      @account ||= begin
        account_proc = self.class.account
        account = account_proc ? account_proc.call(@object) : Nuntius.config.account_for(@object)
        raise Nuntius::MissingAccountException, "no account to send #{@event} for #{self.class.class_name_for(@object)} for" unless account

        account
      end
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
        list = plural ? obj : [obj]
        klass = list.first.class
        klass = klass.base_class if klass.respond_to?(:base_class)
        name = klass.name.demodulize
        name = name.pluralize if plural
        name.underscore
      end

      def class_name_for(obj)
        case obj
        when Array, ActiveRecord::Relation
          obj.first.class.name.demodulize
        when Hash
          "Custom"
        when Class
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

      # The account to send for, from the object, when it isn't
      # Nuntius.config.account_for(object). Subclasses inherit it.
      #
      #   account ->(account) { account }
      def account(account_proc = nil)
        @account = account_proc if account_proc
        return @account if @account

        superclass.account if superclass.respond_to?(:account)
      end

      # Names an event, or a timestamp, for people choosing it in a template:
      #
      #   describe :after_processed, label: -> { I18n.t("screenings.after_processed") }
      #   describe :born_on, label: -> { I18n.t("users.birthday") }
      #
      # Without it the label comes from event_label's translations.
      def describe(event, label:)
        event_descriptions[event.to_sym] = {label: label}
      end

      def event_descriptions
        @event_descriptions ||= {}
      end

      # The events templates can be sent on: the messenger's own methods, and
      # before and after each of the model's timestamps
      def events(class_name = default_class_name)
        (instance_methods(false) + timestamps(class_name).flat_map(&:events)).uniq
      end

      # Leaves timestamps out of the events (updated_at always is). Subclasses
      # inherit it.
      #
      #   hide_timestamps :imported_at, :synced_at
      def hide_timestamps(*names)
        own_hidden_timestamps.concat(names.map(&:to_s))
      end

      def hidden_timestamps
        inherited = superclass.respond_to?(:hidden_timestamps) ? superclass.hidden_timestamps : %w[updated_at]
        inherited + own_hidden_timestamps
      end

      # The model's dates and times templates can be sent around (see Timestamp)
      def timestamps(class_name = default_class_name)
        Timestamp.for(class_name.to_s.safe_constantize).reject { |timestamp| hidden_timestamps.include?(timestamp.name) }
      end

      # The timestamp a before_ or after_ event is about
      def timestamp_for(event, class_name = default_class_name)
        timestamps(class_name).find { |timestamp| timestamp.events.include?(event.to_sym) }
      end

      # Whether templates for the event are sent by TimebasedEventsJob, with an
      # interval: :before or :after around a timestamp
      def timebased(event, class_name = default_class_name)
        timestamp_for(event, class_name) && event.to_s.split("_").first.to_sym
      end

      # An event's name for people, for the model class it's sent for: from
      # describe, the nuntius.events.<model>.<event> translation, the model's
      # state machine event (activerecord.state_machines.<model>.events.<event>),
      # or the event itself
      #
      # A timestamp's events read "<timestamp> is in" and "<timestamp> was",
      # by the timestamp's describe or human_attribute_name.
      def event_label(event, class_name = default_class_name)
        label = described_label(event)
        return label if label

        model = class_name.to_s.safe_constantize
        if (timestamp = timestamp_for(event, class_name))
          return I18n.t(event.to_s.split("_").first, scope: [:nuntius, :timestamps], attribute: timestamp_label(timestamp.name, class_name))
        end

        key = model.respond_to?(:model_name) ? model.model_name.i18n_key : class_name.to_s.underscore
        I18n.t(event, scope: [:nuntius, :events, key], default: nil) ||
          state_machine_event_label(model, event) ||
          event.to_s.humanize(capitalize: false)
      end

      # A timestamp's name for people: from describe, or the model's
      # human_attribute_name
      def timestamp_label(name, class_name = default_class_name)
        described_label(name) || class_name.to_s.constantize.human_attribute_name(name)
      end

      # No longer supported, and ignored: templates are sent around the
      # model's timestamps (see Timestamp), narrowed by their conditions
      def timebased_scope(name, &)
        Nuntius::Deprecator.new.deprecation_warning("timebased_scope",
          "#{self.name}.timebased_scope :#{name} is ignored: use a template around one of the model's timestamps, with conditions (see the changelog)")
      end

      # The objects a timebased template is due for now (or at), around its
      # timestamp: once for each object, or with a recurrence once a day.
      # Nothing when its event isn't a timestamp's.
      def timebased_due(template, at: Time.current)
        timestamp = timestamp_for(template.event, template.klass)
        return Nuntius::Message.none unless timestamp

        sent = Nuntius::Message.select(:nuntiable_id).where(template_id: template.id)
        sent = sent.where(created_at: at.beginning_of_day..) if template.recurrence.present?
        timestamp.due(template, at: at).where.not(id: sent)
      end

      # The objects a timebased template sends to now (or at): those it's due
      # for whose account sends with it, and that meet its conditions. At most
      # max of them, to know whether there are more than a limit.
      def timebased_recipients(template, at: Time.current, max: nil)
        recipients = []
        timebased_due(template, at: at).find_each do |object|
          next unless new(object, template.event).sends?(template)

          recipients << object
          break if max && recipients.size >= max
        end
        recipients
      end

      private

      def default_class_name
        name.to_s.delete_suffix("Messenger")
      end

      def own_hidden_timestamps
        @own_hidden_timestamps ||= []
      end

      def described_label(name)
        label = event_descriptions.dig(name.to_sym, :label)
        label.respond_to?(:call) ? label.call : label
      end

      def state_machine_event_label(model, event)
        return unless model.respond_to?(:state_machines)

        model.state_machines.each_value do |machine|
          found = machine.events[event.to_sym]
          return found.human_name(model) if found
        end
        nil
      end
    end

    private

    # Persists any messenger-provided mail overrides (extra headers and/or a
    # custom SMTP envelope sender) onto the message so they survive the
    # transport delivery job and can be applied by the provider. A blank
    # envelope sender is the null sender (<>).
    def apply_mail_overrides(message)
      message.headers = @headers if @headers.present?
      message.envelope_from = @smtp_envelope_from.presence || Nuntius::AbstractMailProvider::NULL_REVERSE_PATH unless @smtp_envelope_from.nil?
    end

    # Returns the relevant templates for the object / event combination: the
    # account's own and the global ones, narrowed by the messenger's
    # template_scope. Global templates are left out for a transport the
    # account has its own template for.
    def select_templates
      return @templates if @templates

      @templates = Template.unscoped.where(klass: class_names_for(@object), event: event_name_for(@object, @event)).where(enabled: true)
      # Without templates there's no account needed
      return @templates unless @templates.exists?

      @templates = @templates.available_to(account)

      # See if we need to do something additional
      template_scope_proc = self.class.template_scope
      @templates = @templates.instance_exec(@object, &template_scope_proc) if template_scope_proc

      own = @templates.owned_by(account)
      @templates = own.or(@templates.where.not(transport: own.select(:transport)))
    end

    def liquid_context
      assigns = @params || {}
      instance_variables.reject { |i| %w[@params @object @locale @templates @template_scope @headers @smtp_envelope_from @account].include? i.to_s }.each do |i|
        assigns[i.to_s[1..]] = instance_variable_get(i)
      end

      context = {liquid_variable_name_for(@object) => (@object.is_a?(Hash) ? @object[@object.keys.first].deep_stringify_keys : @object)}
      assigns.merge(context)
    end
  end
end
