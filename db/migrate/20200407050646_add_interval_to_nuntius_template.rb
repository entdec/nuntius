class AddIntervalToNuntiusTemplate < ActiveRecord::Migration[5.2]
  def change
    add_column :nuntius_templates, :interval, :string, null: true, default: nil
  end
end
