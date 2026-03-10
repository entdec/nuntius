class AddSubscriberToMessage < ActiveRecord::Migration[8.1]
  def change
    add_reference :nuntius_messages, :subscriber, null: true, type: :uuid, foreign_key: {to_table: :nuntius_subscribers}
  end
end
