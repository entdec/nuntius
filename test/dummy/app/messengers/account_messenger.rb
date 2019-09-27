# frozen_string_literal: true

class AccountMessenger < Nuntius::BaseMessenger
  def created(_account, _params)
    templates
  end
end
