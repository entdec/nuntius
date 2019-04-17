class AddNuntiableToSubscriber < ActiveRecord::Migration[5.2]
  def change
    add_reference :nuntius_subscribers, :nuntiable, polymorphic: true, index: true, type: :uuid
  end
end
