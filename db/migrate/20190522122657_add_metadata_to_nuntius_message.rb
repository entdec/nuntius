# frozen_string_literal: true

class AddMetadataToNuntiusMessage < ActiveRecord::Migration[5.2]
  def change
    add_column :nuntius_messages, :metadata, :jsonb, default: {}
  end
end
