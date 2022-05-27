module Refine
  module Rails
    class Engine < ::Rails::Engine
      initializer "refine-rails.register" do |app|
        begin
          BulletTrain.linked_gems << "refine-rails"
        rescue NameError
        end
      end
    end
  end
end
