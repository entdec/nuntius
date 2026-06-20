# frozen_string_literal: true

require "csv"

module Nuntius
  class ImportSubscribersJob < ApplicationJob
    KNOWN_COLUMNS = %i[first_name last_name email phone_number].freeze

    def perform(list, blob, user)
      blob.open do |io|
        import(list, io, user)
      end
    ensure
      blob.purge
    end

    def import(list, io, user)
      imported = 0
      failed = 0

      detect_column_separator(io)

      CSV.parse(io, headers: true, header_converters: :symbol, converters: ->(v) { v&.strip }, col_sep: @column_separator) do |row|
        row_hash = row.to_h
        attrs = row_hash.slice(*KNOWN_COLUMNS)
        extra = row_hash.except(*KNOWN_COLUMNS).reject { |_, v| v.nil? }
        attrs[:metadata] = extra unless extra.empty?

        subscriber = if attrs[:id].present?
          list.subscribers.find_by(id: attrs[:id])
        else
          list.subscribers.new(attrs)
        end
        if subscriber.save
          imported += 1
        else
          failed += 1
        end
      end

      Signum.success(user, text: I18n.t("nuntius.admin.lists.subscribers.import.success", imported: imported, failed: failed)) if defined?(Signum)
    rescue CSV::MalformedCSVError => e
      Signum.error(user, text: I18n.t("nuntius.admin.lists.subscribers.import.invalid_csv", message: e.message)) if defined?(Signum)
    end

    # Detect column separator based on the first 50 bytes of the CSV, it's naive but works for most cases
    def detect_column_separator(io)
      @column_separator = io.read(128).include?(";") ? ";" : ","
      io.rewind
    end
  end
end
