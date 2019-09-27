# frozen_string_literal: true

class CreateNuntiusSubscribers < ActiveRecord::Migration[5.2]
  def change
    create_table :nuntius_subscribers, id: :uuid do |t|
      t.references :list, index: true, type: :uuid, foreign_key: { to_table: :nuntius_lists }

      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :phone_number
      t.string :tags

      t.timestamps
    end
  end
end
