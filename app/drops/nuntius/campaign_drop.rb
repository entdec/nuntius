# frozen_string_literal: true

module Nuntius
  class CampaignDrop < ApplicationDrop
    delegate :id, :metadata, :name, :transport, to: :@object
  end
end
