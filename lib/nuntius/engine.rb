# frozen_string_literal: true

require "auxilium"
require "faraday"
require "faraday/follow_redirects"
require "liquidum"
require "premailer"
require "state_machines-activerecord"
require "servitium"

# Load tailwindcss-rails (when available) before our engine, so lib/tasks/nuntius_tasks.rake can enhance tailwindcss:build
begin
  require "tailwindcss-rails"
rescue LoadError
  nil
end

module Nuntius
  class Engine < ::Rails::Engine
    isolate_namespace Nuntius

    initializer "nuntius.config" do |_app|
      path = File.expand_path(File.join(File.dirname(__FILE__), ".", "liquid", "{tags,filters}", "*.rb"))
      Dir.glob(path).each do |c|
        require_dependency(c)
      end
    end

    initializer "nuntius.lettermint_webhook" do |app|
      app.config.after_initialize do
        settings = Nuntius.config.lettermint_webhook_settings
        next unless settings && settings[:setup_on_boot]
        # Only on server start, not in tests, consoles or rake tasks (e.g. db:migrate, assets:precompile)
        next if Rails.env.test? || defined?(Rails::Console)
        next if defined?(Rake.application) && Rake.application.top_level_tasks.any?

        Nuntius::LettermintWebhookSetupJob.perform_later
      rescue => e
        Nuntius.config.logger.error("Lettermint: could not enqueue webhook setup: #{e.message}")
      end
    end

    initializer "active_storage.attached" do
      config.after_initialize do
        ActiveSupport.on_load(:active_record) do
          Nuntius::Attachment.include(Nuntius::ActiveStorageHelpers)
        end
      end
    end
  end
end
