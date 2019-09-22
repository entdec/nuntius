module Nuntius
  class Engine < ::Rails::Engine
    isolate_namespace Nuntius

    initializer :append_migrations do |app|
      unless app.root.to_s.match? root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer "active_storage.attached" do
      config.after_initialize do
        ActiveSupport.on_load(:active_record) do
          Nuntius::Message.include(ActiveStorageHelpers)
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
