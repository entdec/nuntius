class CreateNuntiusInboundMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :nuntius_inbound_messages, id: :uuid do |t|
      t.string :status, default: 'pending'
      t.string :transport
      t.string :provider
      t.string :provider_id
      t.string :from
      t.string :to
      t.string :cc
      t.string :subject
      t.text :html
      t.text :text
      t.jsonb :payload
      t.jsonb :metadata
      t.string :digest

      t.timestamps
    end
  end
end
