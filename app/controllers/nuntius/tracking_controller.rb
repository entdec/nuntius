# frozen_string_literal: true

module Nuntius
  class TrackingController < ApplicationController
    skip_before_action :verify_authenticity_token

    # GET /tracking/:message_id/p.gif
    def p
      message = Message.find_by(id: params[:message_id])

      if message&.tracking_enabled?
        # Record the first open time
        message.opened_at ||= Time.current
        message.open_count = (message.open_count || 0) + 1
        message.save
      end

      # Return a 1x1 transparent GIF pixel
      send_data(Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"), type: "image/gif", disposition: "inline")
    end

    # GET /tracking/:message_id/link?url=...
    def link
      message = Message.find_by(id: params[:message_id])
      url = params[:url]

      if message&.tracking_enabled? && url.present?
        # Record the first click time
        message.clicked_at ||= Time.current
        message.click_count = (message.click_count || 0) + 1
        message.save
      end

      # Redirect to the original URL
      if url.present?
        redirect_to url, allow_other_host: true
      else
        head :not_found
      end
    end
  end
end
