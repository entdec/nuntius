# frozen_string_literal: true

require_dependency "nuntius/application_controller"
require "preamble"

module Nuntius
  class CallbacksController < ApplicationController
    skip_before_action :verify_authenticity_token

    layout false

    def create
      message = Nuntius::Message.find(params[:message_id])
      response = message.nuntius_provider(message).callback(params)

      render body: response[2].first,
        content_type: response[1]["Content-Type"],
        layout: false
    end
  end
end
