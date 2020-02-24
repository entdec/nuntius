# frozen_string_literal: true

class CreateNuntiusLocales < ActiveRecord::Migration[5.2]
  def change
    create_table :nuntius_locales, id: :uuid do |t|
      t.string :key
      t.jsonb :data
      t.jsonb :metadata

      t.timestamps
    end
  end
end
