# Nuntius 2.0: every template, campaign, list, layout, locale and message
# belongs to an account (Nuntius.config.account_class), instead of having its
# account in metadata. Templates can be global: used for every account.
#
# The accounts come from metadata (account_id and global, as Nuntius 1.x apps
# filled them through metadata_fields), messages without one get their
# template's or campaign's. Records left without an account stop the
# migration, unless NUNTIUS_ACCOUNT_ID names the account they should get, for
# example for an app with a single account:
#
#   NUNTIUS_ACCOUNT_ID=<id> bin/rails db:migrate
#
# See Nuntius::AccountBackfill.
class AddAccountToNuntiusRecords < ActiveRecord::Migration[8.1]
  def up
    accounts = Nuntius.config.account_class.constantize
    type = accounts.columns_hash[accounts.primary_key].sql_type.to_sym

    Nuntius::AccountBackfill::TABLES.each do |table|
      add_reference table, :account, type: type, index: true
    end
    add_column :nuntius_templates, :global, :boolean, null: false, default: false

    backfill = Nuntius::AccountBackfill.new(connection: connection, fallback_account_id: ENV["NUNTIUS_ACCOUNT_ID"])
    backfill.call
    if (unassigned = backfill.unassigned).any?
      raise ActiveRecord::MigrationError, <<~MESSAGE
        Nuntius records without an account: #{unassigned.map { |table, count| "#{count} in #{table}" }.join(", ")}.
        Set an existing account_id in their metadata, or run the migration with NUNTIUS_ACCOUNT_ID=<id> to give them that account.
      MESSAGE
    end

    Nuntius::AccountBackfill::TABLES.each do |table|
      change_column_null table, :account_id, false
      add_foreign_key table, accounts.table_name, column: :account_id
    end
  end

  def down
    Nuntius::AccountBackfill::TABLES.each do |table|
      execute "UPDATE #{table} SET metadata = COALESCE(metadata, '{}') || jsonb_build_object('account_id', account_id)"
      remove_foreign_key table, column: :account_id
      remove_reference table, :account
    end
    execute "UPDATE nuntius_templates SET metadata = metadata || jsonb_build_object('global', true) WHERE global"
    remove_column :nuntius_templates, :global
  end
end
