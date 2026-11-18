class AddMailboxToNuntiusInboundMessages < ActiveRecord::Migration[8.1]
  def change
    # The message box that fetched it and which of its mailboxes (by name): it's delivered to that message box, and
    # the same mail in two mailboxes is two messages. Mail fetched before is its message box's default mailbox's.
    add_column :nuntius_inbound_messages, :message_box, :string
    add_column :nuntius_inbound_messages, :mailbox, :string
    add_index :nuntius_inbound_messages, %i[provider_id message_box mailbox]

    reversible do |direction|
      direction.up { execute "UPDATE nuntius_inbound_messages SET mailbox = 'default' WHERE transport = 'mail'" }
    end
  end
end
