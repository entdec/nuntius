# frozen_string_literal: true

require_dependency 'nuntius/application_controller'

module Nuntius
  class Api::EventsController < ActionController::Base
    skip_before_action :verify_authenticity_token

    layout false

    def create
      nuntius_params = params.except(:scope, :event, :context, :controller, :action).permit!.to_h
      Nuntius.with({ params[:scope] => params[:context].permit!.to_h }, nuntius_params).message(params[:event])
    end
  end
end
