class UpdateNuntiusMessageSendingToSent < ActiveRecord::Migration[6.0]
  def up
    NuntiusMessage.where(state: 'sending').update_all(state: 'sent')
  end
  def down
    NuntiusMessage.where(state: 'sent').update_all(state: 'sending')
  end
end
