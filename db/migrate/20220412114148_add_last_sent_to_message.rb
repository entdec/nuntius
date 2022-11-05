class AddLastSentToMessage < ActiveRecord::Migration[6.0]
  def change
    add_column :nuntius_messages, :last_sent_at, :datetime, null: true
  end
end
