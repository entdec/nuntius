class CreateNuntiusAttachments < ActiveRecord::Migration[5.2]
  def change
    create_table :nuntius_attachments, id: :uuid do |t|
      t.timestamps
    end

    create_table :nuntius_attachments_messages, id: false do |t|
      t.belongs_to :nuntius_messsages
      t.belongs_to :nuntius_attachments
    end
  end
end
