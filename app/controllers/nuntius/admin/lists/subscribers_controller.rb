# frozen_string_literal: true

require_dependency 'nuntius/application_admin_controller'

module Nuntius
  module Admin
    module Lists
      class SubscribersController < ApplicationAdminController
        before_action :set_objects

        def index
          @subscribers = @list.subscribers.all
        end

        def new
          @subscriber = @list.subscribers.new
          render :edit
        end

        def create
          @subscriber = @list.subscribers.new(subscriber_params)
          @subscriber.save
          respond_with @subscriber, collection_location: -> { admin_list_url(@list) }
        end

        def edit
          @subscriber = @list.subscribers.find(params[:id])
        end

        def update
          @subscriber = @list.subscribers.find(params[:id])
          @subscriber.update(subscriber_params)
          respond_with @subscriber, collection_location: -> { admin_list_url(@list) }
        end

        private

        def subscriber_params
          params.require(:subscriber).permit(:first_name, :last_name, :email, :phone_number, tags: [])
        end

        def set_objects
          @list = List.find(params[:list_id])
        end
      end
    end
  end
end
