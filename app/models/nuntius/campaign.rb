# frozen_string_literal: true

module Nuntius
  class Campaign < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped
    include Nuntius::Concerns::Yamlify
    include Nuntius::Concerns::EmailDesigned

    yamlify :metadata

    belongs_to :list
    accepts_nested_attributes_for :list, reject_if: :all_blank

    belongs_to :old_layout, class_name: "Nuntius::OldLayout", optional: true
    belongs_to :layout, optional: true
    has_many :messages, class_name: "Nuntius::Message"
    validates :name, presence: true
    validate :subscription_link, if: -> { email_design? && list&.allow_unsubscribe }

    state_machine initial: :draft do
      event :publish do
        transition draft: :sending
      end

      event :sent do
        transition sending: :sent
      end

      after_transition(on: :publish) do |campaign, transition|
        DeliverCampaignService.perform_later(campaign: campaign)
      end
    end

    private

    # The Manage subscription block renders this link
    def subscription_link
      return if mjml.include?("{{ subscriber_url }}")

      errors.add(:base, "Add a Manage subscription block: subscribers of #{list.name} must be able to unsubscribe")
    end
  end
end
