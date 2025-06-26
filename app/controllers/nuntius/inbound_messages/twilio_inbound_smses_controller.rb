# frozen_string_literal: true

require_dependency "nuntius/application_controller"
require "twilio-ruby"

module Nuntius
  module InboundMessages
    class TwilioInboundSmsesController < ApplicationController
      skip_before_action :verify_authenticity_token

      layout false

      # Point twilio to you nuntius mount path (/nuntius/inbound_messages/twilio_inbound_smses)
      # { 'ToCountry' => 'NL',
      #   'ToState' => '',
      #   'SmsMessageSid' => 'SMb711289e438f577f230f5837e9c74a08',
      #   'NumMedia' => '0',
      #   'ToCity' => '',
      #   'FromZip' => '',
      #   'SmsSid' => 'SMb711289e438f577f230f5837e9c74a08',
      #   'FromState' => '',
      #   'SmsStatus' => 'received',
      #   'FromCity' => '',
      #   'Body' => 'St',
      #   'FromCountry' => 'NL',
      #   'To' => '+3197014204768',
      #   'MessagingServiceSid' => 'MG790b6bd09f119b54ffb7f03b8841b1c9',
      #   'ToZip' => '',
      #   'NumSegments' => '1',
      #   'MessageSid' => 'SMb711289e438f577f230f5837e9c74a08',
      #   'AccountSid' => 'ACf54dd7a47a8011d65b54d472a7190549',
      #   'From' => '+31612345678',
      #   'ApiVersion' => '2010-04-01',
      #   'controller' => 'nuntius/inbound_messages/twilio_inbound_smses',
      #   'action' => 'create' }
      def create
        inbound_message = Nuntius::InboundMessage.find_or_create_by!(transport: "sms", provider: "twilio", provider_id: params[:SmsSid])
        inbound_message.from = params[:From]
        inbound_message.to = params[:To]
        inbound_message.text = params[:Body]
        inbound_message.metadata = params
        inbound_message.save!

        twiml = Nuntius::DeliverInboundMessageService.perform(inbound_message: inbound_message)

        # twiml = Twilio::TwiML::MessagingResponse.new do |resp|
        #   resp.message body: 'The Robots are coming! Head for the hills!'
        # end

        render body: twiml.to_s,
          content_type: "text/xml",
          layout: false
      end
    end
  end
end
