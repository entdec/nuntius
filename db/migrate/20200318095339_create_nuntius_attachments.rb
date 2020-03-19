class CreateNuntiusAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :nuntius_attachments, id: :uuid do |t|
      t.timestamps
    end

    create_table :nuntius_attachments_messages, id: false do |t|
      t.belongs_to :message, type: :uuid, foreign_key: { to_table: :nuntius_messages }
      t.belongs_to :attachment, type: :uuid, foreign_key: { to_table: :nuntius_attachments }
    end
  end
end
