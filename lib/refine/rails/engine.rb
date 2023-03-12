module Refine
  module Rails
    class Engine < ::Rails::Engine
      config.app_middleware.use(
        Rack::Static,
        urls: ["/refine-assets"],
        root: "#{root}/public"
      )

      initializer "refine-rails.importmap", before: "importmap" do |app|
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("public/refine-assets/**/*.js")
      end

      initializer "refine-rails.register" do |app|
        begin
          BulletTrain.linked_gems << "refine-rails"
        rescue NameError
        end
      end
    end
  end
end
