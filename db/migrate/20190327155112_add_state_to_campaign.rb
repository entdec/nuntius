class AddStateToCampaign < ActiveRecord::Migration[5.2]
  def change
    add_column :nuntius_campaigns, :state, :string
  end
end
