# frozen_string_literal: true

class NuntiusSubscribersTable < ActionTable::ActionTable
  model Nuntius::Subscriber

  column(:name, sortable: false) { |subscriber| subscriber.name }
  column(:email)
  column(:phonenumber)

  initial_order :name, :asc

  row_link { |subscriber| nuntius.edit_admin_list_subscriber_path(params[:list_id], subscriber) }

  private

  def scope
    @scope = Nuntius::Subscriber.where(list_id: params[:list_id])
  end
end
