class AddAutoDescriptionToNuntiusTemplates < ActiveRecord::Migration[8.1]
  def change
    # Whether the admin makes the description from the template's sentence:
    # for new templates, not for those that have one already
    add_column :nuntius_templates, :auto_description, :boolean, null: false, default: true
    up_only do
      execute "UPDATE nuntius_templates SET auto_description = false WHERE COALESCE(description, '') <> ''"
    end
  end
end
