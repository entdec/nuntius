class UpdateNuntiusMessageSendingToSent < ActiveRecord::Migration[5.2]
  def up
    Nuntius::Message.where(status: 'sending').update_all(status: 'sent')
  end
  def down
    Nuntius::Message.where(status: 'sent').update_all(status: 'sending')
  end
end
