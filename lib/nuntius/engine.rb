# frozen_string_literal: true

require "auxilium"
require "evento"
require "inky"
require "httpclient"
require "liquidum"
require "premailer"
require "state_machines-activerecord"
require "servitium"

module Nuntius
  class Engine < ::Rails::Engine
    isolate_namespace Nuntius

    initializer "nuntius.config" do |_app|
      path = File.expand_path(File.join(File.dirname(__FILE__), ".", "liquid", "{tags,filters}", "*.rb"))
      Dir.glob(path).each do |c|
        require_dependency(c)
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
