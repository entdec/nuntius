# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    module Lists
      class SubscribersController < ApplicationAdminController
        before_action :set_objects

        def index
          @subscribers = @list.subscribers.all
        end

        def import
          return unless request.post?

          file = params[:file]
          if file.blank?
            Signum.error(Current.user, text: t(".no_file"))
            redirect_to import_admin_list_subscribers_path(@list) and return
          end

          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: "text/csv"
          )
          ImportSubscribersJob.perform_later(@list, blob, Current.user)

          Signum.info(Current.user, text: t(".queued"))
          redirect_to nuntius.admin_list_path(@list)
        end

        def new
          @subscriber = @list.subscribers.new
          render :edit
        end

        def create
          @subscriber = @list.subscribers.new(subscriber_params)
          @subscriber.save
          # FIXME: This should redirect to list
          respond_with :admin, :list, @subscriber, collection_location: -> { nuntius.admin_list_url(@list) }, location: -> { nuntius.admin_list_url(@list) }, status: :see_other
        end

        def edit
          @subscriber = @list.subscribers.find(params[:id])
        end

        def update
          @subscriber = @list.subscribers.find(params[:id])
          @subscriber.update(subscriber_params)
          # FIXME: This should redirect to list
          respond_with :admin, :list, @subscriber, collection_location: -> { nuntius.admin_list_url(@list) }, location: -> { nuntius.admin_list_url(@list) }, status: :see_other
        end

        private

        def subscriber_params
          params.require(:subscriber).permit(:first_name, :last_name, :email, :phone_number, :metadata_yaml, tags: [])
        end

        def import_params
          params.permit(:file)
        end

        def set_objects
          @list = List.find(params[:list_id])
        end
      end
    end
  end
end
