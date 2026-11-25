# A nuntiable model without a messenger of its own: Nuntius::DefaultMessenger
# sends for it
class Member < ApplicationRecord
  self.table_name = "users"

  belongs_to :account, default: -> { Current.account }

  nuntiable
end
