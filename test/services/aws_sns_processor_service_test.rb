# frozen_string_literal: true

require 'test_helper'

module Nuntius
  class AwsSnsProcessorServiceTest < ActiveSupport::TestCase
    test 'Processes a bounce with DSN' do
      message = Nuntius::Message.create!(transport: 'mail', provider_id: '00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000', status: :sent)
      Nuntius::AwsSnsProcessorService.call(notification: bounce_with_dsn_json('00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000'))
      message.reload
      assert_equal 'bounced', message.status
      assert_equal 'bounce', message.metadata['feedback']['type']
      assert_equal 'Permanent', message.metadata['feedback']['info']['bounceType']
    end

    test 'Processes a bounce without DSN' do
      message = Nuntius::Message.create!(transport: 'mail', provider_id: '00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000', status: :sent)
      Nuntius::AwsSnsProcessorService.call(notification: bounce_without_dsn_json('00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000'))
      message.reload
      assert_equal 'bounced', message.status
      assert_equal 'bounce', message.metadata['feedback']['type']
      assert_equal 'Permanent', message.metadata['feedback']['info']['bounceType']
    end

    test 'Processes a complaint with Feedback' do
      message = Nuntius::Message.create!(transport: 'mail', provider_id: '00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000', status: :sent)
      Nuntius::AwsSnsProcessorService.call(notification: complaint_with_feedback_report('00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000'))
      message.reload
      assert_equal 'complaint', message.status
      assert_equal 'complaint', message.metadata['feedback']['type']
      assert_equal 'abuse', message.metadata['feedback']['info']['complaintFeedbackType']
    end

    test 'Processes a complaint without Feedback' do
      message = Nuntius::Message.create!(transport: 'mail', provider_id: '00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000', status: :sent)
      Nuntius::AwsSnsProcessorService.call(notification: complaint_without_feedback_report('00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000'))
      message.reload
      assert_equal 'complaint', message.status
      assert_equal 'complaint', message.metadata['feedback']['type']
    end

    test 'Processes a delivery notification' do
      message = Nuntius::Message.create!(transport: 'mail', provider_id: '00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000', status: :sent)
      Nuntius::AwsSnsProcessorService.call(notification: delivery_notification_json('00000138111222aa-33322211-cccc-cccc-cccc-ddddaaaa0680-000000'))
      message.reload
      assert_equal 'delivered', message.status
      assert_equal 'a8-70.smtp-out.amazonses.com', message.metadata['feedback']['info']['reportingMTA']
    end

    private

    def bounce_with_dsn_json(message_id)
      {
        "notificationType": 'Bounce',
        "bounce": {
          "bounceType": 'Permanent',
          "reportingMTA": 'dns; email.example.com',
          "bouncedRecipients": [
            {
              "emailAddress": 'jane@example.com',
              "status": '5.1.1',
              "action": 'failed',
              "diagnosticCode": 'smtp; 550 5.1.1 <jane@example.com>... User'
            }
          ],
          "bounceSubType": 'General',
          "timestamp": '2016-01-27T14:59:38.237Z',
          "feedbackId": "<#{message_id}>",
          "remoteMtaIp": '127.0.2.0'
        },
        "mail": {
          "timestamp": '2016-01-27T14:59:38.237Z',
          "source": 'john@example.com',
          "sourceArn": 'arn:aws:ses:us-east-1:888888888888:identity/example.com',
          "sourceIp": '127.0.3.0',
          "sendingAccountId": '123456789012',
          "callerIdentity": 'IAM_user_or_role_name',
          "messageId": "<#{message_id}>",
          "destination": [
            'jane@example.com',
            'mary@example.com',
            'richard@example.com'
          ],
          "headersTruncated": false,
          "headers": [
            {
              "name": 'From',
              "value": '"John Doe" <john@example.com>'
            },
            {
              "name": 'To',
              "value": '"Jane Doe" <jane@example.com>, "Mary Doe" <mary@example.com>, "Richard Doe" <richard@example.com>'
            },
            {
              "name": 'Message-ID',
              "value": 'custom-message-ID'
            },
            {
              "name": 'Subject',
              "value": 'Hello'
            },
            {
              "name": 'Content-Type',
              "value": 'text/plain; charset="UTF-8"'
            },
            {
              "name": 'Content-Transfer-Encoding',
              "value": 'base64'
            },
            {
              "name": 'Date',
              "value": 'Wed, 27 Jan 2016 14:05:45 +0000'
            }
          ],
          "commonHeaders": {
            "from": [
              'John Doe <john@example.com>'
            ],
            "date": 'Wed, 27 Jan 2016 14:05:45 +0000',
            "to": [
              'Jane Doe <jane@example.com>, Mary Doe <mary@example.com>, Richard Doe <richard@example.com>'
            ],
            "messageId": "<#{message_id}>",
            "subject": 'Hello'
          }
        }
      }
    end

    def bounce_without_dsn_json(message_id)
      {
        "notificationType": 'Bounce',
        "bounce": {
          "bounceType": 'Permanent',
          "bounceSubType": 'General',
          "bouncedRecipients": [
            {
              "emailAddress": 'jane@example.com'
            },
            {
              "emailAddress": 'richard@example.com'
            }
          ],
          "timestamp": '2016-01-27T14:59:38.237Z',
          "feedbackId": "<#{message_id}>",
          "remoteMtaIp": '127.0.2.0'
        },
        "mail": {
          "timestamp": '2016-01-27T14:59:38.237Z',
          "messageId": "<#{message_id}>",
          "source": 'john@example.com',
          "sourceArn": 'arn:aws:ses:us-east-1:888888888888:identity/example.com',
          "sourceIp": '127.0.3.0',
          "sendingAccountId": '123456789012',
          "callerIdentity": 'IAM_user_or_role_name',
          "destination": [
            'jane@example.com',
            'mary@example.com',
            'richard@example.com'
          ],
          "headersTruncated": false,
          "headers": [
            {
              "name": 'From',
              "value": '"John Doe" <john@example.com>'
            },
            {
              "name": 'To',
              "value": '"Jane Doe" <jane@example.com>, "Mary Doe" <mary@example.com>, "Richard Doe" <richard@example.com>'
            },
            {
              "name": 'Message-ID',
              "value": message_id
            },
            {
              "name": 'Subject',
              "value": 'Hello'
            },
            {
              "name": 'Content-Type',
              "value": 'text/plain; charset="UTF-8"'
            },
            {
              "name": 'Content-Transfer-Encoding',
              "value": 'base64'
            },
            {
              "name": 'Date',
              "value": 'Wed, 27 Jan 2016 14:05:45 +0000'
            }
          ],
          "commonHeaders": {
            "from": [
              'John Doe <john@example.com>'
            ],
            "date": 'Wed, 27 Jan 2016 14:05:45 +0000',
            "to": [
              'Jane Doe <jane@example.com>, Mary Doe <mary@example.com>, Richard Doe <richard@example.com>'
            ],
            "messageId": "<#{message_id}>",
            "subject": 'Hello'
          }
        }
      }
    end

    def complaint_with_feedback_report(message_id)
      {
        "notificationType": 'Complaint',
        "complaint": {
          "userAgent": 'AnyCompany Feedback Loop (V0.01)',
          "complainedRecipients": [
            {
              "emailAddress": 'richard@example.com'
            }
          ],
          "complaintFeedbackType": 'abuse',
          "arrivalDate": '2016-01-27T14:59:38.237Z',
          "timestamp": '2016-01-27T14:59:38.237Z',
          "feedbackId": message_id
        },
        "mail": {
          "timestamp": '2016-01-27T14:59:38.237Z',
          "messageId": '000001378603177f-7a5433e7-8edb-42ae-af10-f0181f34d6ee-000000',
          "source": 'john@example.com',
          "sourceArn": 'arn:aws:ses:us-east-1:888888888888:identity/example.com',
          "sourceIp": '127.0.3.0',
          "sendingAccountId": '123456789012',
          "callerIdentity": 'IAM_user_or_role_name',
          "destination": [
            'jane@example.com',
            'mary@example.com',
            'richard@example.com'
          ],
          "headersTruncated": false,
          "headers": [
            {
              "name": 'From',
              "value": '"John Doe" <john@example.com>'
            },
            {
              "name": 'To',
              "value": '"Jane Doe" <jane@example.com>, "Mary Doe" <mary@example.com>, "Richard Doe" <richard@example.com>'
            },
            {
              "name": 'Message-ID',
              "value": 'custom-message-ID'
            },
            {
              "name": 'Subject',
              "value": 'Hello'
            },
            {
              "name": 'Content-Type',
              "value": 'text/plain; charset="UTF-8"'
            },
            {
              "name": 'Content-Transfer-Encoding',
              "value": 'base64'
            },
            {
              "name": 'Date',
              "value": 'Wed, 27 Jan 2016 14:05:45 +0000'
            }
          ],
          "commonHeaders": {
            "from": [
              'John Doe <john@example.com>'
            ],
            "date": 'Wed, 27 Jan 2016 14:05:45 +0000',
            "to": [
              'Jane Doe <jane@example.com>, Mary Doe <mary@example.com>, Richard Doe <richard@example.com>'
            ],
            "messageId": "<#{message_id}>",
            "subject": 'Hello'
          }
        }
      }
    end

    def complaint_without_feedback_report(message_id)
      {
        "notificationType": 'Complaint',
        "complaint": {
          "complainedRecipients": [
            {
              "emailAddress": 'richard@example.com'
            }
          ],
          "timestamp": '2016-01-27T14:59:38.237Z',
          "feedbackId": message_id
        },
        "mail": {
          "timestamp": '2016-01-27T14:59:38.237Z',
          "messageId": "<#{message_id}>",
          "source": 'john@example.com',
          "sourceArn": 'arn:aws:ses:us-east-1:888888888888:identity/example.com',
          "sourceIp": '127.0.3.0',
          "sendingAccountId": '123456789012',
          "callerIdentity": 'IAM_user_or_role_name',
          "destination": [
            'jane@example.com',
            'mary@example.com',
            'richard@example.com'
          ],
          "headersTruncated": false,
          "headers": [
            {
              "name": 'From',
              "value": '"John Doe" <john@example.com>'
            },
            {
              "name": 'To',
              "value": '"Jane Doe" <jane@example.com>, "Mary Doe" <mary@example.com>, "Richard Doe" <richard@example.com>'
            },
            {
              "name": 'Message-ID',
              "value": message_id
            },
            {
              "name": 'Subject',
              "value": 'Hello'
            },
            {
              "name": 'Content-Type',
              "value": 'text/plain; charset="UTF-8"'
            },
            {
              "name": 'Content-Transfer-Encoding',
              "value": 'base64'
            },
            {
              "name": 'Date',
              "value": 'Wed, 27 Jan 2016 14:05:45 +0000'
            }
          ],
          "commonHeaders": {
            "from": [
              'John Doe <john@example.com>'
            ],
            "date": 'Wed, 27 Jan 2016 14:05:45 +0000',
            "to": [
              'Jane Doe <jane@example.com>, Mary Doe <mary@example.com>, Richard Doe <richard@example.com>'
            ],
            "messageId": "<#{message_id}>",
            "subject": 'Hello'
          }
        }
      }
    end

    def delivery_notification_json(message_id)
      {
        "notificationType": 'Delivery',
        "mail": {
          "timestamp": '2016-01-27T14:59:38.237Z',
          "messageId": "<#{message_id}>",
          "source": 'john@example.com',
          "sourceArn": 'arn:aws:ses:us-east-1:888888888888:identity/example.com',
          "sourceIp": '127.0.3.0',
          "sendingAccountId": '123456789012',
          "callerIdentity": 'IAM_user_or_role_name',
          "destination": [
            'jane@example.com'
          ],
          "headersTruncated": false,
          "headers": [
            {
              "name": 'From',
              "value": '"John Doe" <john@example.com>'
            },
            {
              "name": 'To',
              "value": '"Jane Doe" <jane@example.com>'
            },
            {
              "name": 'Message-ID',
              "value": message_id
            },
            {
              "name": 'Subject',
              "value": 'Hello'
            },
            {
              "name": 'Content-Type',
              "value": 'text/plain; charset="UTF-8"'
            },
            {
              "name": 'Content-Transfer-Encoding',
              "value": 'base64'
            },
            {
              "name": 'Date',
              "value": 'Wed, 27 Jan 2016 14:58:45 +0000'
            }
          ],
          "commonHeaders": {
            "from": [
              'John Doe <john@example.com>'
            ],
            "date": 'Wed, 27 Jan 2016 14:58:45 +0000',
            "to": [
              'Jane Doe <jane@example.com>'
            ],
            "messageId": "<#{message_id}>",
            "subject": 'Hello'
          }
        },
        "delivery": {
          "timestamp": '2016-01-27T14:59:38.237Z',
          "recipients": ['jane@example.com'],
          "processingTimeMillis": 546,
          "reportingMTA": 'a8-70.smtp-out.amazonses.com',
          "smtpResponse": '250 ok:  Message 64111812 accepted',
          "remoteMtaIp": '127.0.2.0'
        }
      }
    end
  end
end
