# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class SubscribersController < ApplicationController
    # skip_before_action :authenticate_user!, only: %i[show destroy]

    def show
      @subscriber = Nuntius::Subscriber.find_by(id: params[:id])
      if @subscriber
        @list = @subscriber.list
      else
        flash[:notice] = "Subscription not found."
        redirect_to root_path, status: :see_other
      end
    end

    def subscribe
      @subscriber = Nuntius::Subscriber.find(params[:id])
      @subscriber.update(unsubscribed_at: nil)
      flash[:notice] = "Subscription has been restored."
      redirect_to nuntius.subscriber_path(@subscriber), status: :see_other
    end

    def unsubscribe
      @subscriber = Nuntius::Subscriber.find(params[:id])
      @subscriber.touch(:unsubscribed_at)
      flash[:notice] = "Subscription has been removed."
      redirect_to nuntius.subscriber_path(@subscriber), status: :see_other
    end
  end
end
