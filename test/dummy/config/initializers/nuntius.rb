# frozen_string_literal: true

Nuntius.setup do |config|
  config.base_controller = '::ApplicationController'
  config.logger = Rails.logger

  config.protocol :mail
  config.protocol :push
  config.protocol :sms

  config.provider :mail, protocol: :mail

  config.provider :houston, protocol: :push
  config.provider :firebase, protocol: :push

  config.provider :message_bird, protocol: :sms, priority: 1, timeout: 20, settings: { from: 'Soverin', auth_token: 'live_qrV8ZwTAgnqQ6soTZBddZMtjK' }
  config.provider :twilio, protocol: :sms, priority: 2, settings: { sid: 'AC92bf1782ac7790aa62d13f2135a887aa', auth_token: '811738b3a314daa224ce55ca400a97c2', from: '+14153736696' }
end
