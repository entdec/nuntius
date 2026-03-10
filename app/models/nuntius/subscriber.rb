# frozen_string_literal: true

module Nuntius
  class Subscriber < ApplicationRecord
    include Nuntius::Concerns::Yamlify

    belongs_to :list, counter_cache: :subscribers_count
    belongs_to :nuntiable, polymorphic: true, optional: true

    scope :subscribed, -> { where(unsubscribed_at: nil) }

    yamlify :metadata

    def name
      [first_name, last_name].compact.join(" ").presence || email
    end

    def first_name
      return nuntiable.first_name if nuntiable.respond_to?(:first_name)

      super
    end

    def last_name
      return nuntiable.last_name if nuntiable.respond_to?(:last_name)

      super
    end

    def email
      return nuntiable.email if nuntiable.respond_to?(:email)

      super
    end

    def link(campaign, message, tag: true)
      link_text = campaign.metadata["subscriber_url_text"] || I18n.t("subscriber_url_text")
      url = Nuntius::Engine.routes.url_helpers.subscriber_url(self, host: Nuntius.config.host(message), protocol: "https")
      tag ? "<a href=\"#{url}\" data-nuntius-tracking=\"false\">#{link_text}</a>" : url
    end

    def unsubscribe_link(campaign, message)
      Nuntius::Engine.routes.url_helpers.unsubscribe_subscriber_url(self, host: Nuntius.config.host(message), protocol: "https")
    end
  end
end
