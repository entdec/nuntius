# frozen_string_literal: true

require "auxilium"
require "importmap-rails"
require "tess_edit"
require "entdec/view_components"
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

    initializer "nuntius.assets" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
    end

    initializer "nuntius.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/javascript")
    end

    # The editor's compile endpoint (mounted in config/routes.rb) sits behind
    # Nuntius' admin authentication, unless the host app chose a controller itself.
    initializer "nuntius.tess_edit" do
      TessEdit.parent_controller = "Nuntius::ApplicationAdminController" if TessEdit.parent_controller == "ActionController::Base"
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
