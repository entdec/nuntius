class AddMetadataToSubscriber < ActiveRecord::Migration[8.1]
  def change
    add_column :nuntius_subscribers, :metadata, :jsonb, default: {}
  end
end
