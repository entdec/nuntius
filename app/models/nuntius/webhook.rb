# frozen_string_literal: true

module Nuntius
  # Webhooks Nuntius registered with external providers (e.g. Lettermint), with the secret used to verify deliveries
  class Webhook < ApplicationRecord
    validates :provider, presence: true, uniqueness: true
  end
end
