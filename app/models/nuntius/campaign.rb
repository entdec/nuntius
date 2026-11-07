# frozen_string_literal: true

module Nuntius
  class Campaign < ApplicationRecord
    include Nuntius::Concerns::Owned
    include Nuntius::Concerns::Yamlify
    include Nuntius::Concerns::EmailDesigned

    yamlify :metadata

    belongs_to :list
    accepts_nested_attributes_for :list, reject_if: :all_blank

    belongs_to :old_layout, class_name: "Nuntius::OldLayout", optional: true
    belongs_to :layout, optional: true
    validates_same_account :list, :layout
    has_many :messages, class_name: "Nuntius::Message"
    validates :name, presence: true
    validate :subscription_link, if: -> { email_design? && list&.allow_unsubscribe }

    state_machine initial: :draft do
      # A scheduled campaign is published by CampaignPublishJob at its
      # publish_at, or within a minute without one
      event :schedule do
        transition draft: :scheduled
      end

      event :deschedule do
        transition scheduled: :draft
      end

      event :publish do
        transition scheduled: :sending
      end

      event :sent do
        transition sending: :sent
      end

      # Stops a campaign without sending (the rest of) it, keeping the messages
      # it sent so far
      event :cancel do
        transition [:draft, :scheduled, :sending] => :cancelled
      end

      after_transition(on: :schedule) do |campaign, transition|
        CampaignPublishJob.set(wait: 1.minute).perform_later
      end

      after_transition(on: :publish) do |campaign, transition|
        DeliverCampaignService.perform_later(campaign: campaign)
      end
    end

    # What its Liquid can use (see Variables and DeliverCampaignService): itself,
    # the subscriber with its URL, and what the list's subscribers are (their
    # nuntiables), under their messengers' names
    def variable_roots
      types = list ? list.subscribers.where.not(nuntiable_type: nil).distinct.pluck(:nuntiable_type) : []
      types.map { |type| Variables.for_class(type) }.reduce({}, :merge)
        .merge("campaign" => CampaignDrop, "subscriber" => SubscriberDrop, "subscriber_url" => :string)
    end

    private

    # The Manage subscription block renders this link
    def subscription_link
      return if mjml.include?("{{ subscriber_url }}")

      errors.add(:base, "Add a Manage subscription block: subscribers of #{list.name} must be able to unsubscribe")
    end
  end
end
