# frozen_string_literal: true

Nuntius.setup do |config|
  config.base_controller = '::ApplicationController'
  config.logger = Rails.logger

  config.adapter :mail
  config.adapter :push
  config.adapter :sms

  config.driver :mail, adapter: :mail

  config.driver :houston, adapter: :push
  config.driver :firebase, adapter: :push

  config.driver :message_bird, adapter: :sms, priority: 1, timeout: 20, settings: { from: 'Soverin', auth_token: 'live_qrV8ZwTAgnqQ6soTZBddZMtjK' }
  config.driver :twilio, adapter: :sms, priority: 2, settings: { sid: 'AC92bf1782ac7790aa62d13f2135a887aa', auth_token: '811738b3a314daa224ce55ca400a97c2', from: '+14153736696' }
end
