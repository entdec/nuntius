# Nuntius
Short description and motivation.

## Usage

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
        Hallo, dit is een bericht van Soverin!
        <break strength="x-weak" time="100ms"/>
        <p>We geven je zo je wachtwoord-herstel-code, dus pak een pen en schrijf mee.</p>
    </Say>
    <Gather input="dtmf" numDigits="1" action="{{url}}/code">
       <Say language="nl-NL">Druk een toets om verder te gaan.</Say>
    </Gather>
    <Redirect>{{url}}/code</Redirect>
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
  <Redirect>{{url}}/code</Redirect>
</Response>
```
