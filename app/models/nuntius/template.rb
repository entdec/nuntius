# frozen_string_literal: true

module Nuntius
  class Template < ApplicationRecord
    include Nuntius::Concerns::Owned
    include Nuntius::Concerns::Yamlify
    include Nuntius::Concerns::EmailDesigned
    include Nuntius::Concerns::Conditional

    belongs_to :old_layout, class_name: "Nuntius::OldLayout", optional: true
    belongs_to :layout, optional: true
    validates_same_account :layout
    has_many :messages, class_name: "Nuntius::Message", dependent: :nullify

    attribute :transport, default: -> { Nuntius.config.default_transport }

    # The template form's parts of the event and interval (see compose_event):
    # based on an event, or on time: a timestamp it's before or after
    INTERVAL_UNITS = %w[minutes hours days weeks months].freeze
    attribute :based_on, :string
    attribute :timestamp, :string
    attribute :direction, :string
    attribute :interval_amount, :string
    attribute :interval_unit, :string
    before_validation :compose_event, if: -> { self[:based_on].present? }

    LIQUID_TAGS = /{%(?:(?!%}).)*%}|{{(?:(?!}}).)*}}/

    validates :description, presence: true
    validates :from, liquid: true
    validates :to, liquid: true
    validates :subject, liquid: true
    validates :html, liquid: true
    validates :text, liquid: true

    validates :event, presence: true
    validates :event, format: {with: /.+#.+/}, if: ->(t) { t.klass == "Custom" }
    validates :interval, format: {allow_blank: true, with: /\A[0-9]+\s(month|week|day|hour|minute)s?\z/}
    validates :recurrence, inclusion: {in: Timestamp::RECURRENCES.keys, allow_blank: true}
    validates :timebased_limit, numericality: {only_integer: true, greater_than: 0, allow_nil: true}

    # A global template is used for every account, not only for its own
    scope :global, -> { where(global: true) }
    # The templates an account sends with: its own and the global ones
    scope :available_to, ->(account) { owned_by(account).or(global) }

    yamlify :metadata

    # Where a drop (or hash) in its To is sent to, by transport (see addressees)
    ADDRESS_ATTRIBUTES = {"mail" => "email", "lmtp" => "email", "sms" => "phone_number", "voice" => "phone_number"}.freeze

    # The messages it sends: one for each addressee in its To (see addressees),
    # rendered with the addressee as `to`. account is the account they're sent
    # for, by default the template's own.
    def new_messages(object, assigns = {}, params = {}, account: self.account)
      locale_proc = Nuntius::BaseMessenger.messenger_for_obj(object).locale
      locale = instance_exec(object, &locale_proc) if locale_proc
      locale = params[:locale].to_sym if params[:locale]

      addressees(assigns, locale).map do |address, to|
        message = Nuntius::Message.new(template: self, account: account, transport: transport, to: address)
        message.nuntiable = object unless object.is_a? Hash

        message_assigns = assigns.merge("to" => to)
        options = {registers: {"template" => self, "message" => message}}

        message.from = render(:from, message_assigns, locale, options).split(",").reject(&:empty?).join(",")
        message.subject = render(:subject, message_assigns, locale, options)
        message.html = render(:html, message_assigns, locale, options.merge(layout: old_layout&.data))
        message.text = render(:text, message_assigns, locale, options)
        message.payload = render(:payload, message_assigns, locale, options)

        message
      end
    end

    # The first of its messages: deprecated, see new_messages
    def new_message(...)
      Nuntius::Deprecator.new.deprecation_warning("Template#new_message",
        "use Template#new_messages, which gives a message for each addressee")
      new_messages(...).first
    end

    # Whom its To sends to, as [address, to] pairs, where to is what a message
    # to the address renders with as `to`. A To of a single variable, like
    # {{ order.contacts }}, can give drops or hashes (or a list of them): each
    # is an addressee, at its address attribute for the transport (see
    # ADDRESS_ATTRIBUTES), and is the message's `to`. Otherwise each of the
    # comma separated addresses the To renders to is one, and is its `to`.
    def addressees(assigns, locale)
      value = to_value(assigns, locale)
      value = render(:to, assigns, locale) unless value.present? && !value.is_a?(String)

      Array.wrap(value).flat_map do |to|
        to = to.to_liquid
        if to.is_a?(Hash) || to.is_a?(Liquid::Drop)
          address = address_of(to)
          address.present? ? [[address, to]] : []
        else
          to.to_s.split(",").map(&:strip).reject { |address| address.empty? || address == "Liquid error internal" }.map { |address| [address, address] }
        end
      end
    end

    # A class templates are sent for, by its name for people
    def self.klass_label(name)
      return I18n.t("nuntius.templates.custom") if name == "Custom"

      model = name.to_s.safe_constantize
      model.respond_to?(:model_name) ? model.model_name.human : name.to_s
    end

    def klass_label
      self.class.klass_label(klass)
    end

    # Its event by its name for people (see BaseMessenger.event_label)
    def event_label
      messenger ? messenger.event_label(event, klass) : event
    end

    # Whether it's sent by TimebasedEventsJob (see BaseMessenger.timebased)
    def timebased
      messenger&.timebased(event, klass)
    end

    def based_on
      super || ((event.present? && timebased) ? "time" : "event")
    end

    # At most how many messages it sends in a run of TimebasedEventsJob: its
    # own timebased_limit, or config.timebased_limit
    def send_limit
      timebased_limit || Nuntius.config.timebased_limit
    end

    # Whether it's due on a day (a date, or with a recurrence) rather than in
    # an hour; nil when it isn't time based
    def due_today?
      messenger&.timestamp_for(event, klass)&.daily?(self)
    end

    # How many it would send to now, at most one more than its limit; for a
    # date (or with a recurrence) today, also before the send hour. Nil when
    # it isn't time based.
    def due_count
      timestamp = messenger&.timestamp_for(event, klass)
      return unless timestamp && interval.present?

      at = Time.current
      at = [at, at.change(hour: Nuntius.config.timebased_send_hour)].max if timestamp.daily?(self)
      messenger.timebased_recipients(self, at: at, max: send_limit + 1).size
    end

    # The timestamp of a time based template
    def timestamp
      super || messenger&.timestamp_for(event, klass)&.name
    end

    def direction
      super || (event.to_s.start_with?("after") ? "after" : "before")
    end

    def interval_amount
      super || interval.to_s.split(" ").first
    end

    def interval_unit
      super || interval.to_s.split(" ").second&.pluralize || "days"
    end

    # What its Liquid can use (see Variables): the object it's sent for, under
    # its messenger's name for it (none for Custom), and itself. For another
    # class, what it would be (the form, before the class is saved).
    def variable_roots(klass = self.klass)
      Variables.for_class(klass).merge("template" => TemplateDrop)
    end

    def translation_scope
      scope = %w[]
      scope << (old_layout || layout).name.underscore.tr(" ", "_") if old_layout || layout
      scope << klass.underscore.tr("/", "_")
      scope << event
      scope << transport
      scope << description.underscore.gsub(/[^a-z]+/, "_") if description
      scope.join(".")
    end

    # Trix correctly escapes the HTML, but for liquid this is not what we need.
    # This replaces html-entities within the liquid tags ({%...%} and {{...}})
    def html=(html)
      html_unescaped_liquid = html.gsub(LIQUID_TAGS) do |m|
        CGI.unescape_html(m)
      end
      write_attribute :html, html_unescaped_liquid if html
    end

    def interval_duration
      unless interval.blank?
        number, type = interval.split(" ")
        number = number.to_i

        return number.public_send(type) if number.respond_to?(type)
      end

      0.seconds
    end

    def interval_time_range
      return 0.seconds..0.seconds if interval.blank?

      start = if event.start_with?("before")
        interval_duration.after
      else
        interval_duration.ago
      end

      (start - 1.hour)..start
    end

    private

    def messenger
      return if klass.blank? || klass == "Custom" || !klass.safe_constantize

      BaseMessenger.messenger_for_class(klass)
    end

    # From the form's parts: an event has no interval or recurrence; a time
    # before_ or after_ its timestamp, an interval and a recurrence
    def compose_event
      if based_on == "event"
        self.interval = nil
        self.recurrence = nil
        return
      end
      return if timestamp.blank?

      self.event = "#{direction}_#{timestamp}"
      self.interval = "#{interval_amount.to_i} #{interval_unit}" if INTERVAL_UNITS.include?(interval_unit) && interval_amount.present?
    end

    # What a To of only one variable (with filters) is, unrendered: nil for
    # anything else, or when evaluating it fails (render it instead)
    def to_value(assigns, locale)
      nodes = Liquid::Template.parse(to.to_s).root.nodelist.reject { |node| node.is_a?(String) && node.strip.empty? }
      return unless nodes.one? && nodes.first.is_a?(Liquid::Variable)

      context = Liquid::Context.build(environments: [assigns.merge("template" => self).stringify_keys], registers: {"template" => self})
      I18n.with_locale(locale) { nodes.first.render(context) }
    rescue => e
      Nuntius.config.logger.call.warn "Can't evaluate the To of template #{id}: #{e.message}"
      nil
    end

    def address_of(to)
      attribute = ADDRESS_ATTRIBUTES[transport.to_s]
      return unless attribute

      value = to.is_a?(Hash) ? to.stringify_keys[attribute] : to.invoke_drop(attribute)
      value.to_s.strip
    end

    def render(attr, assigns, locale, options = {})
      I18n.with_locale(locale) do
        if attr == :payload
          YAML.safe_load(::Liquidum.render(send(attr), {assigns: assigns.merge("template" => self), registers: {"template" => self}}.merge(options)))
        elsif attr == :html && email_design?
          # Already a whole email: only Liquid is left to render
          ::Liquidum.render(send(attr), {assigns: assigns.merge("template" => self), registers: {"template" => self}}.merge(options.except(:layout)))
        elsif attr == :html
          ::Liquidum.render(send(attr), {filter: "markdown", assigns: assigns.merge("template" => self), registers: {"template" => self}}.merge(options))
        else
          ::Liquidum.render(send(attr), {assigns: assigns.merge("template" => self), registers: {"template" => self}}.merge(options))
        end
      end
    end
  end
end
