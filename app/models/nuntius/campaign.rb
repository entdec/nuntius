# frozen_string_literal: true

module Nuntius
  class Campaign < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped

    belongs_to :list
    accepts_nested_attributes_for :list, reject_if: :all_blank

    belongs_to :layout, optional: true
    has_many :messages, class_name: 'Nuntius::Message'
    validates :name, presence: true

    state_machine initial: :draft do
      event :publish do
        transition draft: :sending
      end

      event :sent do
        transition sending: :sent
      end

      after_transition(on: :publish) do |campaign, transition|
        DeliverCampaignService.perform(campaign: campaign)
      end
    end
  end
end
