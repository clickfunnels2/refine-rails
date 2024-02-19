require_relative "lib/refine/rails/version"

Gem::Specification.new do |spec|
  spec.name        = "refine-rails"
  spec.version     = Refine::Rails::VERSION
  spec.authors     = ["Colleen Schnettler", "Aaron Francis"]
  spec.email       = ["colleen@hammerstone.dev", "aaron@hammerstone.dev"]
  spec.homepage    = "https://rubygems.org/gems/refine-rails"
  spec.summary     = "Visual query builder for Rails"
  spec.description = "Refine is a flexible query builder for your apps. It lets your users filter down to exactly what they're looking for. Completely configured on the backend."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/clickfunnels2/refine-rails"
  spec.metadata["changelog_uri"] = "https://github.com/clickfunnels2/refine-rails/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 6.0"
end
