# frozen_string_literal: true

module Nuntius
  class TeamsTeamsProvider < BaseProvider
    transport :teams

    def deliver
      # NOTE: Attachments are not supported
      # https://adaptivecards.io/designer/
      # https://learn.microsoft.com/en-us/power-automate/overview-adaptive-cards
      # https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?tabs=newteams%2Cdotnet

      args = (message.payload || {}).merge(text: message.text)
      response = Faraday.post(message[:to], JSON.dump(args), {"Content-Type": "application/json"})

      message.status = if response.status == 200
        "sent"
      else
        "undelivered"
      end

      message
    end
  end
end
