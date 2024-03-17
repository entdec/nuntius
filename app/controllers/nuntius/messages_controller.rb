# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class MessagesController < ApplicationController
    layout false

    def show
      @message = Nuntius::Message.find(params[:id])
    end
  end
end
