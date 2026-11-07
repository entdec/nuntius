# frozen_string_literal: true

module Nuntius
  # Moves the owning account of Nuntius' records from metadata (account_id
  # and global, as Nuntius 1.x apps filled them) to the account_id and global
  # columns, for the migration to Nuntius 2.0.
  #
  # A record gets the account in its metadata when that account exists. A
  # message without one gets its template's or campaign's, any record left
  # gets fallback_account_id when given. The keys are removed from the
  # metadata of the records that got their account from it.
  class AccountBackfill
    TABLES = %w[nuntius_templates nuntius_campaigns nuntius_lists nuntius_layouts nuntius_old_layouts nuntius_locales nuntius_messages].freeze
    BATCH_SIZE = 10_000

    attr_reader :connection, :accounts_table, :fallback_account_id

    def initialize(connection: ActiveRecord::Base.connection, fallback_account_id: nil)
      @connection = connection
      @accounts_table = Nuntius.config.account_class.constantize.table_name
      @fallback_account_id = fallback_account_id.presence
    end

    def call
      metadata_tables.each do |table|
        update(table, set: "account_id = accounts.id", from: "#{accounts_table} accounts", where: "accounts.id::text = #{table}.metadata->>'account_id'")
      end
      %w[template campaign].each do |parent|
        update("nuntius_messages", set: "account_id = parents.account_id", from: "nuntius_#{parent}s parents", where: "parents.id = nuntius_messages.#{parent}_id AND parents.account_id IS NOT NULL")
      end
      connection.update("UPDATE nuntius_templates SET global = (metadata->>'global') IN ('true', 't', '1') WHERE metadata ? 'global'")
      metadata_tables.each do |table|
        update(table, set: "metadata = #{table}.metadata - 'account_id' - 'global'", where: "#{table}.metadata ?| array['account_id', 'global'] AND #{table}.account_id IS NOT NULL", unassigned: false)
      end
      return unless fallback_account_id

      TABLES.each { |table| update(table, set: "account_id = #{connection.quote(fallback_account_id)}") }
    end

    # The number of records still without an account, per table
    def unassigned
      TABLES.to_h { |table| [table, connection.select_value("SELECT COUNT(*) FROM #{table} WHERE account_id IS NULL").to_i] }.select { |_table, count| count.positive? }
    end

    private

    # MoveNuntiusMetadataToColumns drops the metadata of some tables later
    def metadata_tables
      TABLES.select { |table| connection.column_exists?(table, :metadata) }
    end

    # Updates the rows of table (joined with from) that match where, BATCH_SIZE
    # at a time, so the messages of a big app aren't one huge update. Only rows
    # without an account, unless unassigned is false.
    def update(table, set:, from: nil, where: nil, unassigned: true)
      condition = [("#{table}.account_id IS NULL" if unassigned), where].compact.join(" AND ")
      rows = "SELECT #{table}.id FROM #{[table, from].compact.join(", ")} WHERE #{condition} LIMIT #{BATCH_SIZE}"
      loop do
        updated = connection.update("UPDATE #{table} SET #{set}#{" FROM #{from}" if from} WHERE #{table}.id IN (#{rows})#{" AND #{where}" if from}")
        break if updated < BATCH_SIZE
      end
    end
  end
end
