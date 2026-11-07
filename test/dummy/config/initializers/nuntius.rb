# frozen_string_literal: true

# Lettermint settings come from the (development) credentials, see: bin/rails credentials:edit --environment development
lettermint = Rails.application.credentials.lettermint || {}

Nuntius.setup do |config|
  config.base_controller = "::ApplicationController"
  config.logger = -> { Rails.logger }

  # The dummy app has no users, so no authentication for the admin pages
  config.admin_authentication_module = nil
  # The environment's own OrbStack domain, which differs per worktree (bin/de)
  config.host = ->(_message) { "app.#{ENV.fetch("DEV_ENV_NAME", "nuntius")}.orb.local" }

  config.transport :mail
  config.transport :lmtp
  config.transport :push
  config.transport :sms
  config.transport :voice
  config.allow_custom_events = true

  config.provider :smtp, transport: :mail, settings: lambda { |_message|
    if lettermint[:smtp_password].present?
      {
        from_header: lettermint[:from_header],
        host: "smtp.lettermint.co",
        port: 587,
        username: "lettermint",
        password: lettermint[:smtp_password],
        allow_list: lettermint[:allow_list] || []
      }
    else
      {
        from_header: "Example <example@example.com>",
        host: "",
        port: "",
        username: "",
        password: "",
        allow_list: ["example.com"]
      }
    end
  }

  # Lettermint has to be able to reach the webhook, app.nuntius.orb.local is only reachable locally, so use a tunnel
  if lettermint[:api_token].present? && lettermint[:webhook_host].present?
    config.lettermint_webhook(
      api_token: lettermint[:api_token],
      project_id: lettermint[:project_id],
      route_id: lettermint[:route_id],
      host: lettermint[:webhook_host]
    )
  end

  # LMTP delivery to a mailbox, on its own transport. The recipient and
  # per-message LMTP server are inline-encoded in the template `to` as
  # `<email>@<host>:<port>`; `host`/`port` are optional fallbacks for plain
  # addresses.
  config.provider :lmtp, transport: :lmtp, settings: {
    from_header: "Example <example@example.com>",
    allow_list: ["example.com"]
  }

  config.provider :houston, transport: :push, settings: {certificate: ""}
  config.provider :firebase, transport: :push, settings: {server_key: ""}

  config.provider :message_bird, transport: :sms, priority: 1, timeout: 20, settings: {from: "YourApp", auth_token: ""}
  config.provider :twilio, transport: :sms, priority: 2, settings: {sid: "", auth_token: "", from: ""}

  config.provider :twilio, transport: :voice, settings: {sid: "", auth_token: "", from: ""}
end
