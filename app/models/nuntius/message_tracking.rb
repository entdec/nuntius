# frozen_string_literal: true

module Nuntius
  class MessageTracking < ApplicationRecord
    belongs_to :message, class_name: "Nuntius::Message"
  end
end
