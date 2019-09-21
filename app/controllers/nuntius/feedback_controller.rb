# frozen_string_literal: true

require_dependency 'nuntius/application_controller'
require 'httpclient'

module Nuntius
  class FeedbackController < ApplicationController
    skip_before_action :verify_authenticity_token

    layout false

    def awssns
      body = JSON.parse(request.body.read)
      if body['Type'] == 'SubscriptionConfirmation'
        HTTPClient.get(body['SubscribeURL'])
      else
        notification = JSON.parse(body['Message'])
        Nuntius::AWSSNSProcessorService.new(notification).call
      end
      head :ok
    end
  end
end
