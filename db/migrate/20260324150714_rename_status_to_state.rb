class RenameStatusToState < ActiveRecord::Migration[8.1]
  def change
    rename_column :nuntius_messages, :status, :state
  end
end
