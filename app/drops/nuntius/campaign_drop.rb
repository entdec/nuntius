# frozen_string_literal: true

module Nuntius
  class CampaignDrop < ApplicationDrop
    delegate :id, :metadata, to: :@object
  end
end
