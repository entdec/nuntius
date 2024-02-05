# frozen_string_literal: true

class NuntiusSubscribersTable < ActionTable::ActionTable
  model Nuntius::Subscriber

  column(:id)
  column(:name, sortable: false)
  column(:email)
  column(:phonenumber)

  initial_order :name, :asc

  row_link { |subscriber| nuntius.edit_admin_list_subscriber_path(subscriber, list_id: subscriber.list) }

  private

  def scope
    @scope = Nuntius::Subscriber.where(list_id: params[:list_id])
  end
end
