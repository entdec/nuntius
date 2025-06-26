class AddDescriptionToList < ActiveRecord::Migration[7.0]
  def change
    add_column :nuntius_lists, :description, :text
  end
end
