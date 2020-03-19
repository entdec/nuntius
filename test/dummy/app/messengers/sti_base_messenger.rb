# frozen_string_literal: true

class StiBaseMessenger < Nuntius::BaseMessenger
  def created(_account, _params)
    templates
  end
end
