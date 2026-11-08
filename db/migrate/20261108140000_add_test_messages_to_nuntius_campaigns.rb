class AddTestMessagesToNuntiusCampaigns < ActiveRecord::Migration[8.1]
  def change
    # A campaign's test messages go to its list's test recipients
    add_column :nuntius_subscribers, :test_recipient, :boolean, default: false, null: false
    # and don't count as the campaign's messages
    add_column :nuntius_messages, :test_message, :boolean, default: false, null: false
  end
end
