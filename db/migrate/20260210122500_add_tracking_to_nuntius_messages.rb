# frozen_string_literal: true

class AddTrackingToNuntiusMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :nuntius_messages, :opened_at, :datetime
    add_column :nuntius_messages, :clicked_at, :datetime
    add_column :nuntius_messages, :open_count, :integer, default: 0
    add_column :nuntius_messages, :click_count, :integer, default: 0

    add_column :nuntius_templates, :open_tracking, :boolean, default: false
    add_column :nuntius_templates, :link_tracking, :boolean, default: false

    create_table :nuntius_message_trackings, id: :uuid do |t|
      t.references :message, type: :uuid, foreign_key: {to_table: :nuntius_messages}
      t.string :url
      t.integer :count, default: 0

      t.timestamps
    end

    add_column :nuntius_campaigns, :open_tracking, :boolean, default: false
    add_column :nuntius_campaigns, :link_tracking, :boolean, default: false
  end
end
