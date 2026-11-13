class AddDescriptionToNuntiusLayouts < ActiveRecord::Migration[8.1]
  def change
    # What it's for, shown under its preview when choosing a layout for a new template
    add_column :nuntius_layouts, :description, :text
  end
end
