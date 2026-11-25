# frozen_string_literal: true

# The template form reads as a sentence: send via [mail] based on [an event]
# on [Order] [shipped], or based on [a time] when [User] [Born on]
# [is in] [4] [weeks] [every year]
class TemplatePresenter < ApplicationPresenter
  # The classes templates can be sent for, by their names for people, but a
  # subclass named as its parent (an STI class whose model_name is its
  # parent's): it's its parent to people, and its messages use its parent's
  # templates too. The template's own class too, when it isn't (or no longer)
  # offered, so saving keeps it
  def klass_options
    names = Nuntius.config.nuntiable_class_names.reject { |name| named_as_its_parent?(name) }
    names += [klass] if klass.present? && !names.include?(klass)
    names
      .map { |name| [Nuntius::Template.klass_label(name), name] }
      .sort_by { |label, _| label.downcase }
  end

  def based_on_options
    %w[event time on_demand].map { |based_on| [t(based_on, scope: "nuntius.based_on"), based_on] }
  end

  # Every class's events that aren't time based, by their names for people,
  # chained to their class. And the template's own event, when its class
  # isn't (or no longer) nuntiable, like its class in klass_options.
  def event_options
    options = chained_options do |messenger, class_name|
      messenger.events(class_name).reject { |event| messenger.timebased(event, class_name) }
        .map { |event| [messenger.event_label(event, class_name), event, {}] }
    end
    return options if klass.blank? || klass == "Custom" || event.blank? || Nuntius.config.nuntiable_class_names.include?(klass)

    options + [[event.to_s.humanize(capitalize: false), event, {"data-chain": klass}]]
  end

  # Every class's timestamps, chained to their class
  def timestamp_options
    chained_options do |messenger, class_name|
      messenger.timestamps(class_name).map { |timestamp| [messenger.timestamp_label(timestamp.name, class_name), timestamp.name, {}] }
    end
  end

  def direction_options
    %w[before after].map { |direction| [t(direction, scope: "nuntius.directions"), direction] }
  end

  def interval_unit_options
    Nuntius::Template::INTERVAL_UNITS.map { |unit| [t(unit, scope: "nuntius.interval_units"), unit] }
  end

  # How often a template about a timestamp comes back, by name
  def recurrence_options
    [[t("nuntius.recurrences.once"), ""]] +
      Nuntius::Timestamp::RECURRENCES.keys.map { |recurrence| [t(recurrence, scope: "nuntius.recurrences"), recurrence] }
  end

  private

  def named_as_its_parent?(name)
    model = name.to_s.safe_constantize
    parent = model.try(:superclass)
    return false unless model.respond_to?(:model_name) && parent.respond_to?(:model_name)

    model.model_name.name == parent.model_name.name
  end

  # [label, value, data-chain: class name], sorted by label, for the
  # nuntius--chained-select controller
  def chained_options
    options = []
    Nuntius.config.nuntiable_class_names.each do |class_name|
      next if class_name == "Custom"

      messenger = Nuntius::BaseMessenger.messenger_for_class(class_name)
      next unless messenger

      yield(messenger, class_name).each do |label, value, data|
        options << [label, value, data.merge("data-chain": class_name)]
      end
    end
    options.sort_by { |label, _| label.downcase }
  end
end
