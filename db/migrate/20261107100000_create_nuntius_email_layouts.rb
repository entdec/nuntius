# Nuntius 2.0: layouts become TessEdit designs.
#
# The old layouts (HTML with {{ content }}) are kept as nuntius_old_layouts,
# and templates and campaigns keep pointing at them through old_layout_id, so
# they render as before until they are converted. The new nuntius_layouts hold
# a TessEdit document (json), its MJML and the compiled HTML.
#
# Campaigns that are not sent yet would be sent with a layout that no longer
# applies, so the migration refuses to run while there are any: send, delete
# or cancel them first.
class CreateNuntiusEmailLayouts < ActiveRecord::Migration[8.1]
  def up
    refuse_unsent_campaigns

    # Foreign keys are named after their table and column, so the new layout_id
    # columns would clash with the old ones: those are dropped and added again.
    remove_foreign_key :nuntius_templates, :nuntius_layouts, column: :layout_id
    remove_foreign_key :nuntius_campaigns, :nuntius_layouts, column: :layout_id
    rename_table :nuntius_layouts, :nuntius_old_layouts
    execute "UPDATE active_storage_attachments SET record_type = 'Nuntius::OldLayout' WHERE record_type = 'Nuntius::Layout'"

    create_table :nuntius_layouts, id: :uuid do |t|
      t.string :name, null: false
      t.jsonb :json, null: false, default: {}
      t.text :mjml
      t.text :html
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    %i[nuntius_templates nuntius_campaigns].each do |table|
      rename_column table, :layout_id, :old_layout_id
      add_foreign_key table, :nuntius_old_layouts, column: :old_layout_id
      add_reference table, :layout, type: :uuid, foreign_key: {to_table: :nuntius_layouts}
      # The template's or campaign's own blocks: the children of the layout's Content block
      add_column table, :json, :jsonb
      # The whole email, layout included, as MJML; html is its compiled HTML
      add_column table, :mjml, :text
      add_column table, :preview_text, :string
    end
  end

  def down
    %i[nuntius_templates nuntius_campaigns].each do |table|
      remove_column table, :preview_text
      remove_column table, :mjml
      remove_column table, :json
      remove_reference table, :layout, foreign_key: {to_table: :nuntius_layouts}
      remove_foreign_key table, :nuntius_old_layouts, column: :old_layout_id
      rename_column table, :old_layout_id, :layout_id
    end

    drop_table :nuntius_layouts
    execute "UPDATE active_storage_attachments SET record_type = 'Nuntius::Layout' WHERE record_type = 'Nuntius::OldLayout'"
    rename_table :nuntius_old_layouts, :nuntius_layouts
    add_foreign_key :nuntius_templates, :nuntius_layouts, column: :layout_id
    add_foreign_key :nuntius_campaigns, :nuntius_layouts, column: :layout_id
  end

  private

  def refuse_unsent_campaigns
    unsent = select_all(<<~SQL).to_a
      SELECT c.id, c.name, c.state,
        COUNT(m.id) FILTER (WHERE m.state <> 'pending') AS sent,
        COUNT(m.id) FILTER (WHERE m.state = 'pending') AS pending
      FROM nuntius_campaigns c LEFT JOIN nuntius_messages m ON m.campaign_id = c.id
      WHERE c.state IN ('draft', 'sending')
      GROUP BY c.id, c.name, c.state
      ORDER BY c.name
    SQL
    return if unsent.empty?

    raise ActiveRecord::MigrationError, <<~MESSAGE
      Nuntius 2.0 can't be installed while campaigns are draft or sending:
      #{unsent.map { |c| "- #{c["name"]} (#{c["id"]}, #{c["state"]}): #{c["sent"]} message(s) sent, #{c["pending"]} pending" }.join("\n")}
      Send or delete them, or cancel them, which keeps the messages a campaign sent so far:
        UPDATE nuntius_campaigns SET state = 'cancelled' WHERE id IN (#{unsent.map { |c| quote(c["id"]) }.join(", ")});
      Then run the migration again.
    MESSAGE
  end
end
