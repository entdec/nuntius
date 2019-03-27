class AddMetadataToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :nuntius_campaigns, :metadata, :jsonb, null: false, default: {}
    add_column :nuntius_lists, :metadata, :jsonb, null: false, default: {}
  end
end
