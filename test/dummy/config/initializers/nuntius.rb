# frozen_string_literal: true

Nuntius.setup do |config|
  config.base_controller = '::ApplicationController'
  config.logger = Rails.logger

  config.transport :mail
  config.transport :push
  config.transport :sms
  config.transport :voice

  config.provider :smtp, transport: :mail, settings: ->(_obj) {
    { from_header: '"Local Express" <do_not_reply@localexpress.nl>', host: 'email-smtp.eu-west-1.amazonaws.com', port: 587, username: 'AKIAIIA7EIIM25OFDEUA', password: 'AgJjPlUKEdMuyIuJ2LshcuvSygCXpTEe6VV/bVwEhZV+' }
  }

  config.provider :houston, transport: :push, settings: { certificate: '' }
  config.provider :firebase, transport: :push, settings: { server_key: 'AAAAhfDlrck:APA91bE7HwqfTkhVfaeMdXiSoeRZdlcIfidVyPfOibVhoTJeoOCiMRxn2E9dGf0PxK_eu7_dUmyVYkFoS8UyIrVujBf6OototKahqGTm_cVAz8lkYnsIGcvrpRYmpk3MkBsV1y3_f73W' }

  config.provider :message_bird, transport: :sms, priority: 1, timeout: 20, settings: { from: 'Soverin', auth_token: 'live_qrV8ZwTAgnqQ6soTZBddZMtjK' }
  config.provider :twilio, transport: :sms, priority: 2, settings: { sid: 'AC92bf1782ac7790aa62d13f2135a887aa', auth_token: '811738b3a314daa224ce55ca400a97c2', from: '+14153736696' }

  config.provider :twilio, transport: :voice, settings: { sid: 'AC92bf1782ac7790aa62d13f2135a887aa', auth_token: '811738b3a314daa224ce55ca400a97c2', from: '+14153736696' }
end
