# frozen_string_literal: true

module Nuntius
  class MessageMessenger < ApplicationMessenger
    template_scope ->(screening) { all }
  end
end
