class CreateNuntiusMessages < ActiveRecord::Migration[5.1]
  def change
    enable_extension 'uuid-ossp'

    create_table :nuntius_messages, id: :uuid do |t|
      t.references :template, index: true, type: :uuid, foreign_key: { to_table: :nuntius_templates }

      t.string :status, default: 'draft'
      t.string :transport
      t.string :provider
      t.string :provider_id

      t.string :request_id # For grouping

      t.string :from
      t.string :to
      t.string :subject
      t.text :html
      t.text :text

      t.timestamps
    end
  end
end
