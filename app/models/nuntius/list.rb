# frozen_string_literal: true

module Nuntius
  class List < ApplicationRecord
    include Nuntius::Concerns::Owned

    has_many :subscribers, dependent: :delete_all

    validates :name, presence: true
    validates :slug, presence: true, uniqueness: true

    accepts_nested_attributes_for :subscribers, reject_if: :all_blank

    scope :subscribed_by, ->(nuntiable) { where(id: nuntiable.nuntius_subscriptions.select(:list_id)) }
    scope :not_subscribed_by, ->(nuntiable) { where.not(id: nuntiable.nuntius_subscriptions.select(:list_id)) }
  end
end
