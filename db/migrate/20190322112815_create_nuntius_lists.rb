# frozen_string_literal: true

class CreateNuntiusLists < ActiveRecord::Migration[5.2]
  def change
    create_table :nuntius_lists, id: :uuid do |t|
      t.string :name
      t.integer :subscribers_count

      t.timestamps
    end
  end
end
