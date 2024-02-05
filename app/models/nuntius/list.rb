# frozen_string_literal: true

module Nuntius
  class List < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped

    has_many :subscribers, counter_cache: :subscribers_count, dependent: :delete_all

    accepts_nested_attributes_for :subscribers, reject_if: :all_blank
  end
end
