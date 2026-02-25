# frozen_string_literal: true

# Use Nokogiri to parse and modify links
require "nokogiri"

module Nuntius
  class EmailTrackingService < ApplicationService
    context do
      attribute :message
    end

    def perform
      return context.message.html unless context.message.link_tracking_enabled? || context.message.open_tracking_enabled?

      tracked_html = context.message.html.dup
      tracked_html = inject_tracking_pixel(tracked_html)
      tracked_html = wrap_links_with_tracking(tracked_html)

      context.message.html = tracked_html
    end

    private

    def inject_tracking_pixel(html)
      return html unless context.message.open_tracking_enabled?

      tracking_pixel_url = tracking_pixel_url(context.message.id)
      tracking_pixel = %(<img src="#{tracking_pixel_url}" width="1" height="1" alt=""/>)

      # Try to inject before closing body tag, otherwise append to end
      if html.include?("</body>")
        html.gsub("</body>", "#{tracking_pixel}</body>")
      else
        html + tracking_pixel
      end
    end

    def wrap_links_with_tracking(html)
      return html unless context.message.link_tracking_enabled?

      doc = Nokogiri::HTML.fragment(html)

      doc.css("a[href]").each do |link|
        next if link["data-nuntius-tracking"] == "false"

        original_url = link["href"]

        # Skip if it's a mailto, tel, anchor link or liquid variable
        next if original_url.start_with?("mailto:", "tel:", "#", "{{")

        # Skip if it's already a tracking link
        next if original_url.include?("/tracking/")

        # Create tracking URL
        tracking_url = tracking_link_url(context.message.id, url: original_url)
        link["href"] = tracking_url
      end

      doc.to_html
    end

    def tracking_pixel_url(message_id)
      Nuntius::Engine.routes.url_helpers.tracking_pixel_message_url(
        message_id,
        host: Nuntius.config.host(context.message)
      )
    end

    def tracking_link_url(message_id, url:)
      Nuntius::Engine.routes.url_helpers.tracking_link_message_url(
        message_id,
        url: url,
        host: Nuntius.config.host(context.message)
      )
    end
  end
end
