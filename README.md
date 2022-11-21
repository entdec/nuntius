# Nuntius

Nuntius offers messaging and notifications for ActiveRecord models in Ruby on Rails applications.

## Setup

Add Nuntius to your Gemfile and run bundle install to install it.

Create an initializer (config/initializers/messaging.rb) and configure as desired:

```ruby
Nuntius.setup do
  # Have Nuntius log to the Rails.logger
  config.logger = Rails.logger

  # Allow custom events (default = false)
  # Enable this option to allow use of Nuntius with a Hash
  config.allow_custom_events = true

  # Configure the transport you want to use

  # Enable e-mail
  config.transport :mail
  # Enable push notifications
  config.transport :push
  # Enable SMS
  config.transport :sms
  # Enable voice
  config.transport :voice
  # Enable Slack
  config.transport :slack

  # Configure providers for each of the transports you enabled above.
  # Advised is to either do this using credentials, environment variables, or somewhere in a model (securely stored away).
  config.provider :slack, transport: :slack, settings: lambda { |_message|
    Rails.application.credentials[:slack]
  }
end
```

Mount the Rails engine in your routes.rb to enable Nuntius' maintenance pages:

```ruby
Rails.application.routes.draw do
  # your own routes ...
  mount Nuntius::Engine, at: '/messaging', as: 'nuntius' # change the path and aliases at your own discretion
end
```

To enable you to send messages with Nuntius you need to make one or more ActiveRecord models nuntiable:

```ruby
class Car < ApplicationRecord
  nuntiable
end
```

Additionally you need to define an extension of the Nuntius::BaseMessenger for the same model with a matching name (in app/messengers):

```ruby
class CarMessenger < Nuntius::BaseMessenger
  def your_event(car, params)
    # your optional logic here
  end
end
```

If you are using the state_machines-activemodel gem you can pass use_state_machine: true to the
nuntiable call, this will automatically define empty methods for these events on the model's
messenger class if they are not defined already.

Additionally the use_state_machine option will add an after_commit hook to the state machine
to automatically trigger the event for the state transition.

## Usage

### With templates

Usually you would call Nuntius programatically with code by using Templates. In this case you would use for example:

```ruby
 Nuntius.event(:your_event, car)
```

When custom events are enabled you can also do the following:

```ruby
 Nuntius.event('shipped', { shipped: { to: 'test@example.com', ref: 'Test-123'} }, attachments: [ { url: 'http://example.com' } ])
```

For the above cases you need to define templates, this is done with the maintenace pages under
/messaging/admin/templates (/messaging is whatever you have defined in your routes file).

When Nuntius#message is called a message will be sent for every matching template. To allow you to
send different messages under different circumstances you can specify a template_scope on the messenger
class that uses the template's metadata in combination with the nuntiable object to determine whether
or not the template should be used.

### Timebased events

If you want to send messages based on time intervals you can add such events to your messenger with the
timebased_scope class method like so:

```ruby
class CarMessenger < Nuntius::BaseMessenger
  # time_range is a range, for a before scope the time_range the interval is added to the current
  # time, the end of the range is 1 hour from the start.
  timebased_scope :before_tuneup do |time_range, metadata|
    cars = Car.where(tuneup_at: time_range)
    cars = cars.where(color: metadata['color']) if metadata['color'].present?
    cars
  end

  # For an after scope the time_range the interval is taken from the current time, the end of the
  # range is 1 hour from its start.
  timebased_scope :after_tuneup do |time_range, metadata|
    cars = Car.where(tuneup_at: time_range)
    cars = cars.where(color: metadata['color']) if metadata['color'].present?
    cars
  end
end
```

This method also requires you to configure a template using the maintenance pages. When you choose
a timebased scope as an event you will be prompted to enter an interval, you can enter anything in the
following formats:

- N minute(s)
- N hour(s)
- N day(s)
- N week(s)
- N month(s)

To send timebased messages you need to execute Nuntius::TimestampBasedMessagesRunner.call, you could do this
in a cronjob every 5 minutes with "bundle exec rails runner Nuntius::TimestampBasedMessagesRunner.call"

### Direct

Another more direct way of using Nuntius is by just instantiating a message:

```ruby
 Nuntius::Message.new(to: 'tom@boxture.com', subject: 'Test', text: 'Test text', nuntiable: channel).deliver_as(:mail)
```

or

```ruby
user = User.find(1)
user.messages.new(to: 'test@example.com', subject: 'Test', text: 'Test text').deliver_as(:mail)
```

Here we still need a nuntiable object, in case provider settings can differ from object to object.

You can also define custom events, which take a scope and an event name:

```ruby
Nuntius.event('packed', packing: {smurrefluts: 'hatseflats'})
```

The main key of the hash passed will also be the liquid variable.

## Transports

### Mail

### Slack

Slack uses the [postMessage](https://api.slack.com/methods/chat.postMessage) method to send messages. It will also upload any attachment the message has prior to sending the message itself.

The message body is specified using `text` and additionally supports the `payload` parameter.

The payload is merged with the `text`, `to` (channel or user) and `from`.

### SMS

SMS just support the `from` (name or phone number), `to` (the phone) and `text` attribute.

Only MessageBird allows for names when sending SMS messages. Messagebird does not support a hypen in the name, just alphabetical characters (A-Za-z).

### Inbound

Inbound messages are also possible, currently mail/IMAP and Twilio inbound SMS are supported.

## Transports

### Mail

#### AWS SES

In case you use AWS SES, you can use the SNS Feedback Notifications to automatically mark messages as read, or deal with complaints and bounces. Create a AWS SNS topic, with a HTTPS subscription with the following URL (pattern):

Use the following URL: https://<host>/messaging/feedback/awssns

The actual URL may be different depending on your routing setup.

The subscription will automatically be confirmed.

Next in AWS SES, configure the SNS topic to receive feedback notifications for Bounce, Complaint and Delivery and include original headers.

### SMS

### Push

### Voice

#### Twilio

Information on voice TWIML is here: https://www.twilio.com/docs/voice/twiml/gather
You can try voices here: https://www.twilio.com/console/voice/twiml/text-to-speech

```
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="nl-NL">
        Hallo, dit is een bericht van Boxture!
        <break strength="x-weak" time="100ms"/>
        <p>We geven je zo je wachtwoord-herstel-code, dus pak een pen en schrijf mee.</p>
    </Say>
    <Gather input="dtmf" numDigits="1" action="{%raw%}{{url}}{%endraw%}/code">
       <Say language="nl-NL">Druk een toets om verder te gaan.</Say>
    </Gather>
    <Redirect>{%raw%}{{url}}{%endraw%}/code</Redirect>
</Response>

---
path: /code
---
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Gather input="dtmf" numDigits="1">
     <Say language="nl-NL">
      <s>Je code is:</s>
      <break strength="x-weak" time="100ms"/>
      <prosody rate="x-slow"><say-as interpret-as="character">1 n a x d 8 b</say-as></prosody>
      <break strength="x-weak" time="1s"/>
      Druk een toets om te herhalen, of hang op.
     </Say>
  </Gather>
  <Redirect>{%raw%}{{url}}{%endraw%}/code</Redirect>
</Response>
```

## Testing

```
bundle exec sidekiq -C test/dummy/config/sidekiq.yml -r test/dummy
```
