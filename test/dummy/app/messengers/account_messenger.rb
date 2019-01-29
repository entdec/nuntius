# frozen_string_literal: true

class AccountMessenger < Nuntius::BaseMessenger
  def created(account, params)
    templates
  end
end
