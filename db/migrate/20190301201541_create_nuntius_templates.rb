# frozen_string_literal: true

class CreateNuntiusTemplates < ActiveRecord::Migration[5.1]
  def change
    enable_extension "pgcrypto"

    create_table :nuntius_templates, id: :uuid do |t|
      t.string :klass
      t.string :event
      t.string :transport

      t.string :description
      t.jsonb :metadata, null: false, default: {}

      t.references :layout, index: true, type: :uuid, foreign_key: {to_table: :nuntius_templates}

      t.string :from
      t.string :to
      t.string :subject
      t.text :html
      t.text :text
      t.jsonb :payload

      t.timestamps
    end
  end
end
