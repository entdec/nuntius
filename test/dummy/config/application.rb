# frozen_string_literal: true

require_relative "boot"

require "rails/all"
# The engines' tailwindcss:config tasks invoke generators
require "rails/generators"

Bundler.require(*Rails.groups)
require "nuntius"

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.active_job.queue_adapter = :inline

    # Run the engine's migrations along with the dummy app's (db:migrate, db:prepare)
    # when run from here, e.g. by bin/setup. The engine's bin/rails sets
    # ENGINE_ROOT, then Active Record adds them itself for the app: tasks.
    unless defined?(ENGINE_ROOT)
      config.paths["db/migrate"] << File.expand_path("../../../db/migrate", __dir__)
    end
  end
end
