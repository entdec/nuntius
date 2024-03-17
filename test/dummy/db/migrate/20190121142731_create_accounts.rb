# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[5.1]
  def change
    enable_extension "pgcrypto"

    create_table :accounts, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
  end
end
