# frozen_string_literal: true

require_dependency 'nuntius/application_controller'

module Nuntius
  class SubscribersController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[show destroy]

    def show
      @subscriber = Nuntius::Subscriber.find_by(id: params[:id])
      if @subscriber
        @list = @subscriber.list
      else
        flash[:notice] = 'Subscription not found.'
        redirect_to root_path, status: :see_other
      end
    end

    def destroy
      @subscriber = Nuntius::Subscriber.find(params[:id])
      @subscriber.destroy
      flash[:notice] = 'Subscription has been removed.'
      redirect_to root_path, status: :see_other
    end
  end
end
