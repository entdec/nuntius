class CreateNuntiusWebhooks < ActiveRecord::Migration[8.1]
  def change
    create_table :nuntius_webhooks, id: :uuid do |t|
      t.string :provider, null: false
      t.string :external_id
      t.string :url
      t.string :secret

      t.timestamps
    end

    add_index :nuntius_webhooks, :provider, unique: true
  end
end
