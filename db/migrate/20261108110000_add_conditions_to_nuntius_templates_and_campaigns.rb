class AddConditionsToNuntiusTemplatesAndCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :nuntius_templates, :conditions, :jsonb, null: false, default: {}
    add_column :nuntius_campaigns, :conditions, :jsonb, null: false, default: {}
  end
end
