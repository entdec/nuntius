module Nuntius
  class ApplicationTable < Mensa::Base
    LINK_CLASS = "underline underline-offset-2 hover:no-underline"

    # Whether the current user may see the table's rows: config.tables_readable
    def readable? = Nuntius.config.tables_readable

    # A link to a message's or subscriber's object (its nuntiable), or just its
    # name when there's no route to it. The html blocks run in the page's view,
    # which may be the host app's, so this isn't a helper.
    def self.object_link(view, object)
      return unless object

      path = object_path(view, object)
      path ? view.link_to(object_name(object), path, class: LINK_CLASS) : object_name(object)
    end

    # What an object is called: its to_s, unless that's Ruby's #<Class:0x…>
    def self.object_name(object)
      return object.to_s unless object.method(:to_s).owner == Kernel

      "#{object.model_name.human} #{object.to_param}"
    end

    # The object's page in the admin or elsewhere: config.object_path's, or a
    # route of the engine it's from (when the app mounts one) or of the app
    def self.object_path(view, object)
      path = Nuntius.config.object_path(object)
      return path if path

      routes = []
      engine = object.class.module_parent.try(:railtie_namespace)
      routes << view.public_send(engine.engine_name) if engine && view.respond_to?(engine.engine_name)
      routes << view.main_app if view.respond_to?(:main_app)

      routes.product([[:admin, object], object]).each do |route, target|
        return route.polymorphic_path(target)
      rescue NoMethodError, ActionController::UrlGenerationError
        next
      end
      nil
    end
  end
end
