# Nuntius 2.0: what Nuntius kept in metadata gets its own columns.
#
# Messages get feedback (the provider's last delivery event), headers (extra
# mail headers a messenger set) and envelope_from (the SMTP envelope sender
# a messenger set, <> for the null sender) from their metadata, which is
# dropped: it only held those and a copy of the template's or campaign's.
# Inbound messages keep what the provider sent as params.
#
# Layouts, lists and locales lose their metadata, which only held their
# account (see AddAccountToNuntiusRecords). The migration stops when one of
# them still has other metadata, unless NUNTIUS_DROP_METADATA=1 says to drop
# it anyway. Templates, campaigns and old layouts keep theirs, for the old
# layouts that read values from it, and subscribers keep theirs.
class MoveNuntiusMetadataToColumns < ActiveRecord::Migration[8.1]
  DROPPED = %i[nuntius_layouts nuntius_lists nuntius_locales].freeze

  def up
    if ENV["NUNTIUS_DROP_METADATA"] != "1"
      left = DROPPED.to_h { |table| [table, select_value("SELECT COUNT(*) FROM #{table} WHERE metadata IS NOT NULL AND metadata <> '{}'").to_i] }.select { |_table, count| count.positive? }
      if left.any?
        raise ActiveRecord::MigrationError, <<~MESSAGE
          Nuntius drops the metadata of layouts, lists and locales, but some still have metadata: #{left.map { |table, count| "#{count} in #{table}" }.join(", ")}.
          Move what you need elsewhere, or run the migration with NUNTIUS_DROP_METADATA=1 to drop it anyway.
        MESSAGE
      end
    end

    add_column :nuntius_messages, :feedback, :jsonb
    add_column :nuntius_messages, :headers, :jsonb, null: false, default: {}
    add_column :nuntius_messages, :envelope_from, :string
    execute "UPDATE nuntius_messages SET feedback = metadata->'feedback' WHERE metadata ? 'feedback'"
    execute "UPDATE nuntius_messages SET headers = metadata->'mail'->'headers' WHERE jsonb_typeof(metadata->'mail'->'headers') = 'object'"
    # A blank envelope sender meant the null sender
    execute "UPDATE nuntius_messages SET envelope_from = COALESCE(NULLIF(metadata->'mail'->>'envelope_from', ''), '<>') WHERE metadata->'mail' ? 'envelope_from'"
    report_dropped_message_metadata
    remove_column :nuntius_messages, :metadata

    DROPPED.each { |table| remove_column table, :metadata }
    rename_column :nuntius_inbound_messages, :metadata, :params
  end

  def down
    rename_column :nuntius_inbound_messages, :params, :metadata
    add_column :nuntius_layouts, :metadata, :jsonb, null: false, default: {}
    add_column :nuntius_lists, :metadata, :jsonb, null: false, default: {}
    add_column :nuntius_locales, :metadata, :jsonb

    add_column :nuntius_messages, :metadata, :jsonb, default: {}
    execute <<~SQL
      UPDATE nuntius_messages SET metadata = jsonb_strip_nulls(jsonb_build_object(
        'feedback', feedback,
        'mail', NULLIF(jsonb_strip_nulls(jsonb_build_object('headers', NULLIF(headers, '{}'), 'envelope_from', envelope_from)), '{}')
      ))
    SQL
    remove_column :nuntius_messages, :feedback
    remove_column :nuntius_messages, :headers
    remove_column :nuntius_messages, :envelope_from
  end

  private

  # The rest of a message's metadata was a copy of its template's or campaign's,
  # which they keep
  def report_dropped_message_metadata
    keys = select_rows(<<~SQL)
      SELECT k, COUNT(*) FROM nuntius_messages m, jsonb_object_keys(m.metadata) k
      WHERE jsonb_typeof(m.metadata) = 'object' AND k NOT IN ('account_id', 'global', 'feedback', 'mail')
      GROUP BY k ORDER BY 2 DESC, 1
    SQL
    return if keys.empty?

    say "Dropping the rest of the messages' metadata, copied from their template or campaign: #{keys.map { |key, count| "#{key} (#{count})" }.join(", ")}"
  end
end
