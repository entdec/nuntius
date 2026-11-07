# Nuntius 2.0: layouts become TessEdit designs.
#
# The old layouts (HTML with {{ content }}) are kept as nuntius_old_layouts,
# and templates and campaigns keep pointing at them through old_layout_id, so
# they render as before until they are converted. The new nuntius_layouts hold
# a TessEdit document (json), its MJML and the compiled HTML.
#
# Campaigns that are not sent yet would be sent with a layout that no longer
# applies, so the migration refuses to run while there are any: send or delete
# them first.
class CreateNuntiusEmailLayouts < ActiveRecord::Migration[8.1]
  def up
    unsent = select_value("SELECT COUNT(*) FROM nuntius_campaigns WHERE state IN ('draft', 'sending')").to_i
    if unsent.positive?
      raise ActiveRecord::MigrationError, "Nuntius 2.0 can't be installed while #{unsent} campaign(s) are draft or sending. Send or delete them first, then run the migration again."
    end

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
end
