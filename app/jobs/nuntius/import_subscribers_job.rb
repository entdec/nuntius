# frozen_string_literal: true

require "csv"

module Nuntius
  class ImportSubscribersJob < ApplicationJob
    KNOWN_COLUMNS = %i[first_name last_name email phone_number].freeze

    def perform(list, blob, user)
      csv_content = blob.download

      imported = 0
      failed = 0

      CSV.parse(csv_content, headers: true, header_converters: :symbol) do |row|
        row_hash = row.to_h
        attrs = row_hash.slice(*KNOWN_COLUMNS)
        extra = row_hash.except(*KNOWN_COLUMNS).reject { |_, v| v.nil? }
        attrs[:metadata] = extra unless extra.empty?

        subscriber = list.subscribers.new(attrs)
        if subscriber.save
          imported += 1
        else
          failed += 1
        end
      end

      Signum.success(user, text: I18n.t("nuntius.admin.lists.subscribers.import.success", imported: imported, failed: failed))
    rescue CSV::MalformedCSVError => e
      Signum.error(user, text: I18n.t("nuntius.admin.lists.subscribers.import.invalid_csv", message: e.message))
    ensure
      blob.purge
    end
  end
end
