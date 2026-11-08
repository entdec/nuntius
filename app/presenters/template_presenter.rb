# frozen_string_literal: true

# The template form reads as a sentence: send via [mail] based on [an event]
# on [Order] [shipped], or based on [a time] when [User] [Born on]
# [is in] [4] [weeks] [every year]
class TemplatePresenter < ApplicationPresenter
  # The classes templates can be sent for, by their names for people.
  # The template's own class too, when it isn't (or no longer) nuntiable, so
  # saving keeps it
  def klass_options
    names = Nuntius.config.nuntiable_class_names
    names += [klass] if klass.present? && !names.include?(klass)
    names
      .map { |name| [Nuntius::Template.klass_label(name), name] }
      .sort_by { |label, _| label.downcase }
  end

  def based_on_options
    %w[event time].map { |based_on| [t(based_on, scope: "nuntius.based_on"), based_on] }
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
