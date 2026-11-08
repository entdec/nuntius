# frozen_string_literal: true

module Nuntius
  # A date or time on a nuntiable model that templates can be sent around,
  # without a timebased_scope: "when a user's born_on is in 4 weeks", "when a
  # screening's processed_at was 2 weeks ago". The model's date and datetime
  # columns, and the `_at` keys of its stores (store_accessor).
  #
  # A template's event is before_<name> ("is in") or after_<name> ("was ...
  # ago"), its interval how long before or after, and its recurrence whether
  # it comes back every day, week, month, quarter, half year or year (a
  # birthday) or happens once.
  Timestamp = Data.define(:model, :name, :store, :date) do
    # Months per period, for recurrences that come back on the same day of
    # the month (nil: by days)
    self::RECURRENCES = {"daily" => nil, "weekly" => nil, "monthly" => 1, "quarterly" => 3, "half_yearly" => 6, "yearly" => 12}.freeze

    def self.for(model)
      return [] unless model.is_a?(Class) && model < ActiveRecord::Base && model.table_exists?

      columns = model.columns_hash.values
        .select { |column| %i[date datetime].include?(column.type) }
        .map { |column| new(model: model, name: column.name, store: nil, date: column.type == :date) }
      stored = model.stored_attributes.flat_map do |store, keys|
        keys.map(&:to_s).select { |key| key.end_with?("_at") }
          .map { |key| new(model: model, name: key, store: store.to_s, date: false) }
      end
      (columns + stored).uniq(&:name)
    end

    def events
      [:"before_#{name}", :"after_#{name}"]
    end

    # The objects the template is due for now (or at). A date (a date column,
    # or any timestamp with a recurrence) is due on its day, from
    # config.timebased_send_hour; a time in the hour up to it.
    def due(template, at: Time.current)
      target = template.event.to_s.start_with?("before") ? at + template.interval_duration : at - template.interval_duration
      recurrence = template.recurrence.presence
      return due_at((target - 1.hour)..target) unless daily?(template)
      return model.none if at.hour < Nuntius.config.timebased_send_hour

      due_on(target.to_date, recurrence)
    end

    # Whether it's due on a day (a date, or with a recurrence) rather than in
    # an hour
    def daily?(template)
      date || template.recurrence.present?
    end

    private

    def due_at(range)
      model.where("#{sql} BETWEEN ? AND ?", range.first, range.last)
    end

    def due_on(day, recurrence)
      value = "(#{sql})::date"
      return model.where("#{value} = ?", day) unless recurrence

      months = self.class::RECURRENCES.fetch(recurrence)
      scope = model.where("#{value} <= ?", day)
      case recurrence
      when "daily" then scope
      when "weekly" then scope.where("(CAST(? AS date) - #{value}) % 7 = 0", day)
      else
        # The months since the date, a whole number of periods, and the date
        # that many months on is the day (January 31 a month on is February 28)
        since = "((EXTRACT(YEAR FROM CAST(? AS date)) - EXTRACT(YEAR FROM #{value})) * 12 + EXTRACT(MONTH FROM CAST(? AS date)) - EXTRACT(MONTH FROM #{value}))::int"
        scope.where("#{since} % ? = 0", day, day, months)
          .where("(#{value} + make_interval(months => #{since}))::date = ?", day, day, day)
      end
    end

    def sql
      table = model.connection.quote_table_name(model.table_name)
      if store
        "(#{table}.#{model.connection.quote_column_name(store)}->>#{model.connection.quote(name)})::timestamp"
      else
        "#{table}.#{model.connection.quote_column_name(name)}"
      end
    end
  end
end
