# Nuntius
Nuntius offers messaging and notifications for Ruby on Rails. 

## Setup
Add Nuntius to your Gemfile, run bundle install and add an initializer (config/initializers/nuntius.rb)

```ruby
Nuntius.setup do
  # Have Nuntius log to the Rails.logger
  config.logger = Rails.logger

  # Allow custom events (default = false)
  # Enable this option to allow use of Nuntius with a Hash 
  config.allow_custom_events = true
 
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

  # ... to be explained further
end
```

## Usage

Usually you would call Nuntius programatically with code by using Templates. In this case you would use for example:
```ruby
 Nuntius.with(shipment).message(event.to_s)
```

When custom events are enabled you can also do the following"
```ruby
 Nuntius.with( { whs: { to: 'tom@boxture.com', ref: 'Test-123'} }, attachments: [ { url: 'http://example.com' } ]).message('shipped')
```

another, more direct way of using Nuntius is by just instantiating a message:
```ruby
 Nuntius::Message.new(to: 'tom@boxture.com', subject: 'Test', text: 'Test text', nuntiable: channel).deliver_as(:mail)
```
Here we still need a nuntiable object, in case provider settings can differ from object to object.

You can also define custom events, which take a scope and an event name:
```ruby
Nuntius.with(packing: {smurrefluts: 'hatseflats'}).message(:packed)
```
The main key of the hash passed will also be the liquid variable.

## Transports

### Mail
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
