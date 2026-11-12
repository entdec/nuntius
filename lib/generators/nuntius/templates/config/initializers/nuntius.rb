# frozen_string_literal: true

Nuntius.setup do |config|
  config.base_controller = "::ApplicationController"
  config.logger = -> { Rails.logger }

  config.transport :mail
  config.transport :push
  config.transport :sms
  config.transport :voice
  config.allow_custom_events = true

  config.provider :smtp, transport: :mail, settings: lambda { |_message|
    {
      from_header: "Example <example@example.com>",
      host: "",
      port: "",
      username: "",
      password: "",
      allow_list: ["example.com"]
    }
  }

  # LMTP delivery to a mailbox. Mail to an address with its LMTP server in it,
  # `<email>@<host>:<port>` (e.g. `user@example.com@mx.internal:24`), goes to
  # this provider instead of to SMTP.
  # config.provider :lmtp, transport: :mail, settings: {
  #   from_header: "Example <example@example.com>",
  #   allow_list: ["example.com"]
  # }

  # Receive delivery, bounce, open and click events from Lettermint. Nuntius creates the webhook with Lettermint
  # and checks it on every server start. `route_id` is optional, `host` defaults to `config.host`.
  # config.lettermint_webhook(
  #   api_token: ENV["LETTERMINT_TEAM_TOKEN"],
  #   project_id: "your-project-id",
  #   route_id: "your-route-id",
  #   host: "https://app.example.com"
  # )

  config.provider :houston, transport: :push, settings: {certificate: ""}
  config.provider :firebase, transport: :push, settings: {server_key: ""}

  config.provider :message_bird, transport: :sms, priority: 1, timeout: 20, settings: {from: "YourApp", auth_token: ""}
  config.provider :twilio, transport: :sms, priority: 2, settings: {sid: "", auth_token: "", from: ""}

  config.provider :twilio, transport: :voice, settings: {sid: "", auth_token: "", from: ""}
end
