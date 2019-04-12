class AddEnabledToTemplates < ActiveRecord::Migration[5.2]
  def change
    add_column :nuntius_templates, :enabled, :boolean, default: true
  end
end
