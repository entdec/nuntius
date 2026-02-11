# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class MessagesController < ApplicationController
    layout false
    skip_before_action :verify_authenticity_token
    before_action :set_objects

    def show
    end

    # GET /messages/:message_id/pixel.gif
    def pixel
      if @message&.open_tracking_enabled?
        # Record the first open time
        @message.opened_at ||= Time.current
        @message.open_count = (@message.open_count || 0) + 1
        @message.save
      end

      # Return a 1x1 transparent GIF pixel
      send_data(Base64.decode64("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"), type: "image/gif", disposition: "inline")
    end

    # GET /messages/:message_id/link?url=...
    def link
      url = params[:url]

      if @message&.link_tracking_enabled? && url.present?
        # Record the first click time
        @message.clicked_at ||= Time.current
        @message.click_count = (@message.click_count || 0) + 1
        @message.save
      end

      # Redirect to the original URL
      if url.present?
        redirect_to url, allow_other_host: true
      else
        head :not_found
      end
    end

    private

    def set_objects
      @message = Nuntius::Message.find(params[:id])
    end
  end
end
