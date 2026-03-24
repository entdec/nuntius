class AddPublishAtToCampaign < ActiveRecord::Migration[8.1]
  def change
    add_column :nuntius_campaigns, :publish_at, :datetime
  end
end
