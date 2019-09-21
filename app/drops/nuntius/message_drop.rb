# frozen_string_literal: true

module Nuntius
  class MessageDrop < ApplicationDrop
    delegate :id, :from, :to, :subject, :html, :text, to: :@object

    def base_url
      Nuntius::Engine.routes.url_helpers.message_url(@object.id, host: host)
    end
  end
end
