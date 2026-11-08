class AddRecurrenceToNuntiusTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :nuntius_templates, :recurrence, :string
  end
end
