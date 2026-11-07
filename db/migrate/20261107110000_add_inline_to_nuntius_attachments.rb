class AddInlineToNuntiusAttachments < ActiveRecord::Migration[7.1]
  def change
    # Images the email shows itself (embed_image), referred to as cid:<content_id>
    add_column :nuntius_attachments, :inline, :boolean, default: false, null: false
    add_column :nuntius_attachments, :content_id, :string
  end
end
