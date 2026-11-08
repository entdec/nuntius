class AddBirthdayAndStampsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :born_on, :date
    add_column :users, :stamps, :jsonb, default: {}
  end
end
