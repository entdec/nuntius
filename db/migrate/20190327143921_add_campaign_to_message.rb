class AddCampaignToMessage < ActiveRecord::Migration[5.2]
  def change
    add_reference :nuntius_messages, :campaign, type: :uuid, foreign_key: { to_table: :nuntius_campaigns }
  end
end
