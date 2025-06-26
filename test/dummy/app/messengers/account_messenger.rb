# frozen_string_literal: true

class AccountMessenger < Nuntius::BaseMessenger
  def created(_account, _params)
  end

  def translationtest(_account, _params)
  end

  # For an after scope the time_range the interval is taken from the current time, the end of the
  # range is 1 hour from its start.
  timebased_scope :after_created do |time_range, metadata|
    Account.where("created_at BETWEEN ? AND ?", time_range.first, time_range.last)
  end
end
