# frozen_string_literal: true

module Nuntius
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path("../templates", __FILE__)

    def create_initializer_file
      template "config/initializers/nuntius.rb"
    end

    def add_route
      return if Rails.application.routes.routes.detect { |route| route.app.app == Nuntius::Engine }
      route %(mount Nuntius::Engine => "/nuntius")
    end

    def copy_migrations
      rake "nuntius:install:migrations"
    end

    def tailwindcss_config
      rake "nuntius:tailwindcss:config"
    end
  end
end
