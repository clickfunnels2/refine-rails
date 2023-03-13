module Refine
  module Rails
    class Engine < ::Rails::Engine
      # Serve static assets in the consumer app from `public/refine-assets`
      config.app_middleware.insert_before(
        ::ActionDispatch::Static,
        Rack::Static,
        urls: ["/refine-assets"],
        root: Refine::Rails::Engine.root.join("public")
      )

      initializer "refine-rails.importmap", before: "importmap" do |app|
        app.config.importmap.paths << root.join("config/importmap.rb")
        app.config.importmap.cache_sweepers << root.join("public/**/*.js")
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
