# frozen_string_literal: true

class AddPayloadToNuntiusMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :nuntius_messages, :payload, :jsonb
  end
end
