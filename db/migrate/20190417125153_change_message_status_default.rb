# frozen_string_literal: true

class ChangeMessageStatusDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:nuntius_messages, :status, from: "draft", to: "pending")

    Nuntius::Message.where(status: "draft").update(status: "pending")
  end
end
