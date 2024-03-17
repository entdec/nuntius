# frozen_string_literal: true

module Nuntius
  module Admin
    module Layouts
      class AttachmentsController < ApplicationController
        before_action :set_objects

        def index
        end

        def create
          params[:attachments].each do |file|
            @layout.attachments.attach(file)
          end
        end

        def destroy
          attachment = @layout.attachments.find_by(id: params[:id])
          attachment&.purge

          render :create
        end

        private

        def set_objects
          @layout = Nuntius::Layout.visible.find(params[:layout_id]) if params[:layout_id]
        end
      end
    end
  end
end
