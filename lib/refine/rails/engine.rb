module Refine
  module Rails
    class Engine < ::Rails::Engine
      # Serve static assets in the consumer app from `public/refine-assets`
      # @see README.md
      config.app_middleware.insert_before(
        ::ActionDispatch::Static,
        Rack::Static,
        urls: ["/refine-assets"],
        root: Refine::Rails::Engine.root.join("public")
      )

      initializer "refine-rails.importmap", before: "importmap" do |app|
        # Add the engine's importmap path to the consuming Rails app
        app.config.importmap.paths << root.join("config/importmap.rb")

        # Add paths that should be cache swept when file changes occur. This
        # is used in development / test environments by the Rails app consuming
        # this engine.
        app.config.importmap.cache_sweepers << root.join("public/**/*.js")
      end

      initializer "refine-rails.setup_assets" do
        Refine::Rails::Engine.config.assets.precompile += %w[ refine_rails_manifest.js ]
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
