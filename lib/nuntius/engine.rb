# frozen_string_literal: true

module Nuntius
  class Engine < ::Rails::Engine
    isolate_namespace Nuntius

    initializer 'nuntius.config' do |_app|
      path = File.expand_path(File.join(File.dirname(__FILE__), '.', 'liquid', '{tags,filters}', '*.rb'))
      Dir.glob(path).each do |c|
        require_dependency(c)
      end
    end

    initializer 'active_storage.attached' do
      config.after_initialize do
        ActiveSupport.on_load(:active_record) do
          Nuntius::Attachment.include(Nuntius::ActiveStorageHelpers)
        end
      end
    end

    #
    # initializer "webpacker.proxy" do |app|
    #   insert_middleware = begin
    #     Nuntius.webpacker.config.dev_server.present?
    #   rescue
    #     nil
    #   end
    #   next unless insert_middleware
    #
    #   app.middleware.insert_before(
    #     0, Webpacker::DevServerProxy, # "Webpacker::DevServerProxy" if Rails version < 5
    #     ssl_verify_none: true,
    #     webpacker: Nuntius.webpacker
    #   )
    # end
  end
end
