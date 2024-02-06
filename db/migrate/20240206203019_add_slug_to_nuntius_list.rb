class AddSlugToNuntiusList < ActiveRecord::Migration[7.1]
  def change
    add_column :nuntius_lists, :slug, :string
    add_index :nuntius_lists, :slug, unique: true
    add_column :nuntius_lists, :allow_unsubscribe, :boolean, default: true, null: false

    add_column :nuntius_subscribers, :unsubscribed_at, :timestamp
  end
end
