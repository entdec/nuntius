# frozen_string_literal: true

require_dependency "nuntius/application_controller"

module Nuntius
  class SubscribersController < ApplicationController
    # skip_before_action :authenticate_user!, only: %i[show destroy]
    skip_before_action :verify_authenticity_token, only: :unsubscribe
    layout "empty"

    def new
      @subscriber = Nuntius::Subscriber.new(list: Nuntius::List.find(params[:list_id]))
      render :edit
    end

    def create
      @subscriber = Nuntius::Subscriber.new(subscriber_params)
      if @subscriber.save
        Signum.success(request.session.id, text: "You have been subscribed.")
        redirect_to nuntius.edit_subscriber_path(@subscriber), status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def edit
      @subscriber = Nuntius::Subscriber.find(params[:id])
      @list = @subscriber.list
    end

    def update
      @subscriber = Nuntius::Subscriber.find(params[:id])
      @list = @subscriber.list
      if @subscriber.update(subscriber_params)
        Signum.success(request.session.id, text: "Subscription has been updated.")
        redirect_to nuntius.edit_subscriber_path(@subscriber), status: :see_other
      else
        render :edit, status: :unprocessable_entity
      end
    end

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
      Signum.success(request.session.id, text: "Subscription has been restored.")

      redirect_to nuntius.subscriber_path(@subscriber), status: :see_other
    end

    def unsubscribe
      @subscriber = Nuntius::Subscriber.find(params[:id])
      @subscriber.touch(:unsubscribed_at)
      Signum.success(request.session.id, text: "Subscription has been removed.")
      redirect_to nuntius.subscriber_path(@subscriber), status: :see_other
    end

    private

    def subscriber_params
      params.require(:subscriber).permit(:email, :list_id, :first_name, :last_name, :phone_number)
    end
  end
end
