class UpdateNuntiusMessageSendingToSent < ActiveRecord::Migration[5.2]
  def up
    Nuntius::Message.where(state: 'sending').update_all(state: 'sent')
  end
  def down
    Nuntius::Message.where(state: 'sent').update_all(state: 'sending')
  end
end
