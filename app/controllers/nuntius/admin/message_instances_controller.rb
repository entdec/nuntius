# frozen_string_literal: true

class Admin::MessageInstancesController < ApplicationController
  def show
    @message_instance = MessageInstance.find(params[:id])
    render layout: false
  end

  def resend
    @message_instance = MessageInstance.find(params[:id]).tap(&:resend!)
    case @message_instance.messagable
    when Shipment
      redirect_to shipment_path(@message_instance.messagable)
    when User
      redirect_to admin_user_path(@message_instance.messagable)
    else
      head 200
    end
  end
end
