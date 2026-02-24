# frozen_string_literal: true

module Nuntius
  class MessageTrackingsTable < Nuntius::ApplicationTable
    definition do
      model Nuntius::MessageTracking

      column(:url)
      column(:count)
      column(:updated_at)

      order updated_at: :desc
    end

    private

    def scope
      @scope = Nuntius::MessageTracking.where(message_id: params[:message_id])
    end
  end
end
