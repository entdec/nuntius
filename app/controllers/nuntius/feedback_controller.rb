# frozen_string_literal: true

require_dependency 'nuntius/application_controller'

module Nuntius
  class FeedbackController < ApplicationController
    skip_before_action :verify_authenticity_token

    layout false

    def awssns
      body = JSON.parse(request.body.read)
      notification = JSON.parse(body['Message'])
      Nuntius::AWSSNSProcessorService.new(notification).call
      head :ok
    end
  end
end
