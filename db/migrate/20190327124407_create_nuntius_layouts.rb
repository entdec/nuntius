# frozen_string_literal: true

class CreateNuntiusLayouts < ActiveRecord::Migration[5.2]
  def up
    create_table :nuntius_layouts, id: :uuid do |t|
      t.string :name

      t.text :data
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    remove_reference :nuntius_templates, :layout, index: true, type: :uuid, foreign_key: { to_table: :nuntius_templates }
    add_reference :nuntius_templates, :layout, index: true, type: :uuid, foreign_key: { to_table: :nuntius_layouts }
    add_reference :nuntius_campaigns, :layout, index: true, type: :uuid, foreign_key: { to_table: :nuntius_layouts }
  end

  def down
    drop_table :nuntius_layouts
    remove_reference :nuntius_templates, :layout, index: true, type: :uuid, foreign_key: { to_table: :nuntius_layouts }
    add_reference :nuntius_templates, :layout, index: true, type: :uuid, foreign_key: { to_table: :nuntius_templates }
  end
end
