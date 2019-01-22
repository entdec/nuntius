class CreateNuntiusMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :nuntius_messages, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.string :from
      t.string :to
      t.string :subject
      t.text :html
      t.text :text

      t.string :request_id # For grouping
      t.string :driver_id
      t.string :status

      t.timestamps
    end
  end
end
