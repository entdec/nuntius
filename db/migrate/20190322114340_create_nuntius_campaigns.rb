# frozen_string_literal: true

class CreateNuntiusCampaigns < ActiveRecord::Migration[5.2]
  def change
    create_table :nuntius_campaigns, id: :uuid do |t|
      t.string :name
      t.string :transport, default: 'mail'
      t.references :list, index: true, type: :uuid, foreign_key: { to_table: :nuntius_lists }

      t.string :from
      t.string :subject
      t.text :text
      t.text :html

      t.timestamps
    end
  end
end
