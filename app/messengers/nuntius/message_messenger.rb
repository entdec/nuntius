# frozen_string_literal: true

module Nuntius
  class MessageMessenger < ApplicationMessenger
    template_scope ->(screening) { all }

    # For an after scope the time_range the interval is taken from the current time, the end of the
    # range is 1 hour from its start.
    timebased_scope :after_opened do |time_range, metadata|
      Screening.where("opened_at BETWEEN ? AND ?", time_range.first, time_range.last)
    end

    timebased_scope :after_clicked do |time_range, metadata|
      Screening.where("clicked_at BETWEEN ? AND ?", time_range.first, time_range.last)
    end

    timebased_scope :after_sent do |time_range, metadata|
      Screening.where("last_sent_at BETWEEN ? AND ?", time_range.first, time_range.last)
    end
  end
end
