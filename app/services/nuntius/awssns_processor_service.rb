# frozen_string_literal: true

###
# Process feedback from the amazon mail delivery service. Feedback looks like this:
#  {"Type"=>"Notification", "MessageId"=>"a00966b6-51a5-53f7-a966-35d0e8f878ce", "TopicArn"=>"arn:aws:sns:eu-west-1:218893591873:localexpress-email-feedback",
#  "Message"=>"{\"notificationType\":\"Delivery\",\"mail\":{\"timestamp\":\"2018-05-04T19:40:12.637Z\",\"source\":\"do_not_reply@localexpress.nl\",\
# "sourceArn\":\"arn:aws:ses:eu-west-1:218893591873:identity/localexpress.nl\",\"sourceIp\":\"52.59.100.253\",\"sendingAccountId\":\"218893591873\",
# \"messageId\":\"010201632cab47dd-924f80f8-4ae2-4ba0-9c8b-050db003711a-000000\",\"destination\":[\"mercedes.tuin@gmail.com\"],
# \"headersTruncated\":false,\"headers\":[{\"name\":\"Received\",\"value\":\"from localhost.localdomain (ec2-52-59-100-253.eu-central-1.compute.amazonaws.com [52.59.100.253]) by email-smtp.amazonaws.com with SMTP (SimpleEmailService-2762311919) id 4AtiQr5QXc6CZ3uJYW4D for mercedes.tuin@gmail.com; Fri, 04 May 2018 19:40:12 +0000 (UTC)\"},{\"nam
#
#
module Nuntius
  class AWSSNSProcessorService < ApplicationService
    def initialize(notification)
      @notification = notification
      @type         = @notification['notificationType']
    end

    def perform
      unless message_id
        Nuntius.config.logger.warn("SNS / SES message could not determine message id: #{@notification}")
        return false
      end
      unless message
        Nuntius.config.logger.warn("SNS / SES message for unknown message with message id: #{message_id}")
        return false
      end
      Nuntius.config.logger.info("SNS /SES updating message #{message.id} for #{@type}")

      case @type
      when 'Delivery'
        process_delivery
      when 'Bounce'
        process_bounce
      when 'Complaint'
        process_complaint
      else
        false
      end
    end

    private

    def process_delivery
      message.state = :delivered
      message.feedback = { 'type': 'delivery', 'info': @notification['delivery'] }
      message.save!
    end

    def process_bounce
      message.state = :bounced
      message.feedback = { 'type': 'bounce', 'info': @notification['bounce'] }
      message.save!
    end

    def process_complaint
      message.state = :complaint
      message.feedback = { 'type': 'complaint', 'info': @notification['complaint'] }
      message.save!
    end

    def message_id
      @message_id ||= @notification.dig('mail', 'commonHeaders', 'messageId')&.[](1...-1)
    end

    def message
      @message ||= Nuntius::Message.find_by(provider_id: message_id)
    end
  end
end
