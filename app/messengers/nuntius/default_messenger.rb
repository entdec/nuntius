# frozen_string_literal: true

module Nuntius
  # The messenger of a nuntiable class without one of its own: templates are
  # sent for its records as they are, on its state machine's and life cycle's
  # events, around its timestamps, and on demand. An app writes a messenger
  # only for what this one doesn't do.
  class DefaultMessenger < BaseMessenger
  end
end
