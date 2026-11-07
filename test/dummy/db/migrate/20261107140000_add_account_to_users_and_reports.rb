class AddAccountToUsersAndReports < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :account, type: :uuid, foreign_key: true
    add_reference :reports, :account, type: :uuid, foreign_key: true
  end
end
