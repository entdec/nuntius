# frozen_string_literal: true

require_dependency "nuntius/application_admin_controller"

module Nuntius
  module Admin
    module Lists
      class SubscribersController < ApplicationAdminController
        before_action :set_objects
        # An app with its own import turns Nuntius' off (config.subscribers_import)
        before_action -> { head :not_found }, only: :import, unless: -> { Nuntius.config.subscribers_import }

        def index
          @subscribers = @list.subscribers.all
        end

        def import
          return unless request.post?

          file = params[:file]
          return redirect_to(import_admin_list_subscribers_path(@list), alert: t(".no_file"), status: :see_other) if file.blank?

          blob = ActiveStorage::Blob.create_and_upload!(
            io: file,
            filename: file.original_filename,
            content_type: "text/csv"
          )
          ImportSubscribersJob.perform_later(@list, blob, Current.user)

          redirect_to nuntius.admin_list_path(@list), notice: t(".queued"), status: :see_other
        end

        def new
          @subscriber = @list.subscribers.new
          render :edit
        end

        def create
          @subscriber = @list.subscribers.new(subscriber_params)
          @subscriber.save
          respond_with_saved @subscriber, edit_admin_list_subscriber_path(@list, @subscriber)
        end

        def edit
          @subscriber = @list.subscribers.find(params[:id])
        end

        def update
          @subscriber = @list.subscribers.find(params[:id])
          @subscriber.update(subscriber_params)
          respond_with_saved @subscriber, edit_admin_list_subscriber_path(@list, @subscriber)
        end

        private

        def subscriber_params
          params.require(:subscriber).permit(:first_name, :last_name, :email, :phone_number, :test_recipient, :metadata_yaml, tags: [])
        end

        def import_params
          params.permit(:file)
        end

        def set_objects
          @list = List.visible.find(params[:list_id])
        end
      end
    end
  end
end
