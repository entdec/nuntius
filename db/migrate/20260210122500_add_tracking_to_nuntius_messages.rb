# frozen_string_literal: true

class AddTrackingToNuntiusMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :nuntius_messages, :opened_at, :datetime
    add_column :nuntius_messages, :clicked_at, :datetime
    add_column :nuntius_messages, :open_count, :integer, default: 0
    add_column :nuntius_messages, :click_count, :integer, default: 0

    add_column :nuntius_templates, :tracking_enabled, :boolean, default: false
  end
end
