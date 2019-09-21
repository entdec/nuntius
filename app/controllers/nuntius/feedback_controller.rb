# frozen_string_literal: true

require_dependency 'nuntius/application_controller'
require 'curb'

module Nuntius
  class FeedbackController < ApplicationController
    skip_before_action :verify_authenticity_token

    layout false

    def awssns
      body = JSON.parse(request.body.read)
      if body['Type'] == 'SubscriptionConfirmation'
        Curl::Easy.perform(body['SubscribeURL'])
      else
        notification = JSON.parse(body['Message'])
        Nuntius::AWSSNSProcessorService.new(notification).call
      end
      head :ok
    end
  end
end
