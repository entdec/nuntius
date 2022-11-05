# frozen_string_literal: true

require_dependency 'nuntius/application_controller'
require 'httpclient'

module Nuntius
  class FeedbackController < ApplicationController
    skip_before_action :verify_authenticity_token

    layout false

    def awssns
      Nuntius::AwsSnsProcessorService.perform(notification: ::JSON.parse(request.body.read))
      head :ok
    end
  end
end
